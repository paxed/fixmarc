use strict;
use warnings;

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


# https://api.finto.fi/rest/v1/search?vocab=yso-aika&query=2010-luku&fields=topConceptOf

my %yso_aika;

sub fetch_ysoaika {
    my ($fixer, $term) = @_;

    if (!defined($yso_aika{$term})) {
        my $t;
        eval {
            $t = uri_escape($term);
        };
        if ($@) {
            $fixer->error("could not uri_escape \"$term\"");
            return undef;
        }
        my $response = HTTP::Tiny->new->get('https://api.finto.fi/rest/v1/search?vocab=yso-aika&query='.$t.'&fields=topConceptOf');
        die "Failed to fetch data from finto API!\n" unless $response->{success};
        my $data = decode_json($response->{content});
        $yso_aika{$term} = $data->{'results'}[0] || "ERROR";
    }
    return $yso_aika{$term};
}

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub fix_ysoaika_singlefield {
    my ($fixer, $f) = @_;

    my $sf_a = $f->subfield('a') || "";
    my $sf_2 = $f->subfield('2') || "";
    my $sf_0 = $f->subfield('0') || "";

    if ($sf_a eq "") {
        $fixer->msg("Field ".$f->tag()."\$a is null.");
        return;
    }

    my $new_a = trim($sf_a);

    if ($new_a =~ /^(.+)\.$/) {
        $new_a = $1;
    }
    $new_a =~ s/\N{EN DASH}/-/g;

    if ($new_a =~ /^([0-9]{3}0)-([0-9]{3}9)$/) {
        my $year1 = int($1);
        my $year2 = int($2);

        $new_a = $year1."-luku (vuosikymmen)" if ($year1 + 9 == $year2);
    }

    if ($sf_a ne $new_a) {
        $f->update('a' => $new_a);
        $fixer->msg("Field ".$f->tag()."\$a:\"".$sf_a."\"=>\"".$new_a."\"");
    }


    my $ysodata = fetch_ysoaika($fixer, $new_a);

    if (!defined($ysodata) || $ysodata eq "ERROR") {
        $fixer->error("Field ".$f->tag()."\$a:\"".$new_a."\" finto fetch failed");
    } elsif (($sf_0 eq "") && ($sf_0 ne $ysodata->{'uri'})) {
        $f->update('0' => $ysodata->{'uri'});
        $fixer->msg("Field ".$f->tag()."\$0:\"".$sf_0."\"=>\"".$ysodata->{'uri'}."\"");

        my $lang = "";

        $lang = "yso/fin" if ($ysodata->{'lang'} eq 'fi');
        $lang = "yso/swe" if ($ysodata->{'lang'} eq 'sv');

        $f->update('2' => $lang) if (($lang ne "") && ($sf_2 ne $lang));
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
