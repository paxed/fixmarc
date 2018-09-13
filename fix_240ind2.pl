use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_240_ind2 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('240');
    foreach my $f (@flist) {
        my $ind = $f->indicator(2) || "";
        if ($ind !~ /^[0-9]$/) {
            $f->set_indicator(2, "0");
            $fixer->msg("Changed 240.ind2:'".$ind."'=>'0'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="240"])\') > 0',
    'func' => \&fix_240_ind2
                         });
$fixer->run();
