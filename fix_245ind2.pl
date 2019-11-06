use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_245_ind2 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('245');
    foreach my $f (@flist) {
        my $ind = $f->indicator(2) . "";
        if ($ind !~ /^[0-9]$/) {
            my $s = $f->subfield('a');
            if ($s) {
                my $lang = '';
                my $f008 = $record->field('008');
                if (defined($f008)) {
                    my $f008data = $f008->data();
                    if (length($f008data) == 40) {
                        $lang = lc(substr($f008data, 35, 3));
                    }
                }

                my $ival = 0;
                if ($s =~ /^(The |An |A |L'|La |Les |El |Il |Un |Det |Den |Ett )/i) {
                    $ival = length($1);
                } elsif ($lang eq 'ger' && $s =~ /^(Der |Die |Das )/i) {
                    $ival = length($1);
                }
                $f->set_indicator(2, "".$ival);
                $fixer->msg("Changed 245.ind2:'".$ind."'=>'".$ival."'");
            }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="245"])\') > 0',
    'func' => \&fix_245_ind2
                         });
$fixer->run();
