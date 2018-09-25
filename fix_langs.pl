use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;
use XML::Simple;

use open ':std', ':encoding(UTF-8)';

my $LANGUAGESXML='/tmp/languages.xml';

my %lang;

system("wget http://www.loc.gov/standards/codelists/languages.xml -O \"$LANGUAGESXML\"") if (! -f $LANGUAGESXML);

my $ref = XMLin($LANGUAGESXML);
my $languages = $ref->{'languages'}->{'language'};

foreach my $l (@{$languages}) {
    my $code = $l->{'code'};
    my $name = (ref($l->{'name'}) eq 'HASH' ? $l->{'name'}{'content'} : $l->{'name'});
    next if (ref($code) eq 'HASH' && $code->{'status'} eq 'obsolete');

    $lang{$code} = $name;
}
$lang{'|||'} = 'Not coded';


sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub trlang {
    my $l = shift;
    $l = lc($l);
    $l = 'zxx' if ($l eq 'non');
    $l = 'zxx' if ($l eq 'xxx');
    $l = 'fre' if ($l eq 'fra' || $l eq 'fr ');
    $l = '|||' if ($l eq '   ');

    return $l;
}

sub fix_languages {
    my ($fixer, $record) = @_;

    my $f008 = $record->field('008');
    if (defined($f008)) {
        my $f008data = $f008->data();

        if (length($f008data) == 40) {
            my $l = substr($f008data, 35, 3);
            my $ol = $l;
            $l = trlang($l);
            if (!defined($lang{$l}) || ($l ne $ol)) {
                if (!defined($lang{$l})) {
                    $fixer->error("008=>'".substr($f008data, 35, 3)."' not valid lang");
                } elsif ($l ne $ol) {
                    my $tmp = str_replace_nth($f008data, 35, $l);
                    $f008->update($tmp);
                    $fixer->msg("Updated 008:'".$f008data."'=>'".$tmp."'");
                }
            }
        }
    }

    my @flist = $record->field('0..');
    my $prevfld;

    foreach my $f (@flist) {

        if ($f->tag() ne '041') {
            $prevfld = $f;
            next;
        }

        my @sfa = $f->subfields();
        my @alist = ();
        my $fld = MARC::Field->new('041', $f->indicator(1), $f->indicator(2), '9' => '');
        my $fldadd = 0;

        foreach my $sf (@sfa) {
            if ($sf->[0] =~ /[a-z]/) {
                my $l = $sf->[1];
                my $ol = $l;
                $l = trlang($l);
                if (!defined($lang{$l}) || ($l ne $ol)) {
                    if (!defined($lang{$l})) {
                        $fixer->error("041\$".$sf->[0]."=>'".$sf->[1]."' not valid lang");
                        $fld->add_subfields($sf->[0] => $sf->[1]);
                    } else {
                        $fld->add_subfields($sf->[0] => $l);
                        $fixer->msg("Changed 041\$".$sf->[0].":'".$sf->[1]."'=>'".$l."'");
                        $fldadd = 1;
                    }
                } else {
                    $fld->add_subfields($sf->[0] => $l);
                    $fixer->msg("Added 041\$".$sf->[0].":'".$l."'");
                }
            } else {
                $fld->add_subfields($sf->[0] => $sf->[1]);
                $fixer->msg("Added 041\$".$sf->[0].":'".$sf->[1]."'");
            }
        }
        if ($fldadd) {
            $fld->delete_subfield(code => '9');
            $record->delete_fields($f);
            if (defined($prevfld)) {
                $record->insert_fields_after($prevfld, $fld);
            } else {
                $record->insert_fields_ordered($fld);
            }

            $prevfld = $fld;
        } else {
            $prevfld = $f;
        }
    }
}


my $fixer = FixMarc->new({ 'func' => \&fix_languages });
$fixer->run();
