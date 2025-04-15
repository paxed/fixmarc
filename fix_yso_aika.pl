use strict;
use warnings;
use utf8;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

use URI::Escape;
use HTTP::Tiny;
use JSON;

use Data::Dumper;

# Fix 388 and 648 by adding subfield 0 url
# also adjust old format decade "1900-1909" to the correct form
# also change some indicators



my %yso_aika;

sub fetch_ysoaika {
    my ($fixer, $term, $searchtype) = @_;

    #$fixer->msg("fetch_ysoaika(".$term.")");
    
    if (!defined($yso_aika{$term})) {
        my $t;

        eval {
            $t = uri_escape($term);
        };
        if ($@) {
            $fixer->error("could not uri_escape \"$term\"");
            return undef;
        }
        $t =~ s/%E5/%C3%A5/g; # å
        #$t =~ s/%2A/*/g;

        my $urli = 'https://api.finto.fi/rest/v1/search?vocab=yso-aika&query='.$t.'&fields=topConceptOf';
        my $response = HTTP::Tiny->new->get($urli);
        die "Failed to fetch data from finto API!\n" unless $response->{success};
        #$fixer->msg("fetch urli:\"".$urli."\"");
        my $data = decode_json($response->{content});

        if (!defined($data->{'results'}[0]) && ($term !~ /\*/) && ($searchtype == 1)) {
            return fetch_ysoaika($fixer, $term . "*");
        } else {
            $yso_aika{$term} = $data->{'results'}[0] || "ERROR";
        }
    }
    return $yso_aika{$term};
}

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub fix_ysoaika_singlefield {
    my ($fixer, $f) = @_;

    my $sf_a = $f->subfield('a') || "";
    my $sf_2 = $f->subfield('2') || "";
    my $sf_0 = $f->subfield('0') || "";
    my $sf_9 = trim($f->subfield('9') || "");

    my $ysodata;

    if ($sf_a eq "") {
        $fixer->msg("Field ".$f->tag()."\$a is null.");
        return;
    }

    # delete internal Koha authority link, we put the Finto link in subfield 0
    $f->delete_subfield('9') if ($sf_9 =~ /^[0-9]+$/);

    my $new_a = trim($sf_a);

    if ($new_a =~ /^(.+)\.$/) {
        $new_a = $1;
    }
    $new_a =~ s/\N{EN DASH}/-/g;

    $new_a =~ s/ j\.a\.a$/ jaa/g if ($new_a =~ / j\.a\.a$/);
    $new_a =~ s/ e\.a\.a$/ eaa/g if ($new_a =~ / e\.a\.a$/);

    if ($new_a =~ /^([0-9]{3}0)-([0-9]{3}9)(-luku)?$/) {
        my $year1 = int($1);
        my $year2 = int($2);

        $new_a = $year1."-luku (vuosikymmen)" if ($year1 + 9 == $year2);
        $ysodata = fetch_ysoaika($fixer, $new_a, 1);
    } elsif ($new_a =~ /[0-9]([0-9])0-(luku|talet)$/) {
        my $kymmen = $1 || "0";
        my $talet = $2 || "";
        $ysodata = fetch_ysoaika($fixer, $new_a, 0);
        if (!defined($ysodata) || $ysodata eq "ERROR") {
            my $xa;
            if ($kymmen eq "0") {
                $xa = $new_a." (vuosisata)" if ($talet eq "luku");
                $xa = $new_a." (århundrade)" if ($talet eq "talet");
            } else {
                $xa = $new_a." (vuosikymmen)" if ($talet eq "luku");
                $xa = $new_a." (årtionde)" if ($talet eq "talet");
            }
            $ysodata = fetch_ysoaika($fixer, $xa, 0);
            if (!defined($ysodata) || $ysodata eq "ERROR") {
                $ysodata = fetch_ysoaika($fixer, $xa, 1);
            }
            if (!defined($ysodata) || $ysodata eq "ERROR") {
                # nothing
            } else {
                $new_a = $xa;
            }
        }
        if (!defined($ysodata) || $ysodata eq "ERROR") {
            $ysodata = fetch_ysoaika($fixer, $new_a, 1);
        }
    } elsif ($new_a =~ /^[0-9][0-9][1-9][0-9]$/) {
        # if exaclty eg. "2010", don't search for "2010*"
        $ysodata = fetch_ysoaika($fixer, $new_a, 0);
        if (!defined($ysodata) || $ysodata eq "ERROR") {
            $ysodata = fetch_ysoaika($fixer, $new_a, 1);
        }
    } else {
        $ysodata = fetch_ysoaika($fixer, $new_a, 1);
    }


    if (!defined($ysodata) || $ysodata eq "ERROR") {
        $fixer->error("Field ".$f->tag()."\$a:\"".$new_a."\" finto fetch failed");
    } else {
        if (($sf_0 eq "") && ($sf_0 ne $ysodata->{'uri'})) {
            $f->update('0' => $ysodata->{'uri'});
            $fixer->msg("Field ".$f->tag()."\$0:\"".$sf_0."\"=>\"".$ysodata->{'uri'}."\"");

            my $lang = "";

            $lang = "yso/fin" if ($ysodata->{'lang'} eq 'fi');
            $lang = "yso/swe" if ($ysodata->{'lang'} eq 'sv');

            $f->update('2' => $lang) if (($lang ne "") && ($sf_2 ne $lang));

            $new_a = $ysodata->{'prefLabel'} if ($new_a ne $ysodata->{'prefLabel'});
        }

    }

    if ($sf_a ne $new_a) {
        $f->update('a' => $new_a);
        $fixer->msg("Field ".$f->tag()."\$a:\"".$sf_a."\"=>\"".$new_a."\"");
    }

    my $ind2 = $f->indicator(2) . "";

    if (($f->tag() eq '648') && ($ysodata eq "ERROR") &&
        ($new_a =~ /^[0-9]{4}(-[0-9]{4})?$/) && ($ind2 eq '7')) {
        $f->set_indicator(2, '4');
        $f->delete_subfield(code => '2');
    }
}

sub fix_ysoaika {
    my ($fixer, $record) = @_;

    foreach my $f ($record->field('388')) {
        fix_ysoaika_singlefield($fixer, $f);
    }

    my @flist = $record->field('648');
    foreach my $f (@flist) {
        fix_ysoaika_singlefield($fixer, $f);
    }

}


my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="388" or @tag="648"])\') > 0',
    'func' => \&fix_ysoaika
                         });
$fixer->run();
