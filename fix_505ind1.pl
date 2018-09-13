use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_505_ind1 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('505');
    foreach my $f (@flist) {
        my $ind = $f->indicator(1) . "";
        if ($ind !~ /^[0128]/) {
            my $newind = "0";
            $f->set_indicator(1, $newind);
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="505"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="505"]/@ind1\') not in ("0", "1", "2", "8")',
    'func' => \&fix_505_ind1
                         });
$fixer->run();
