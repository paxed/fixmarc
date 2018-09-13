use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_700_ind2 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('700');
    foreach my $f (@flist) {
        my $ind = $f->indicator(2) || "";
        if ($ind !~ /^[ 2]$/) {
            $f->set_indicator(2, " ");
            $fixer->msg("Changed 700.ind2:'".$ind."'=>' '");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="700"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="700"]/@ind2\') not in (" ", "2")',
    'func' => \&fix_700_ind2
                         });
$fixer->run();
