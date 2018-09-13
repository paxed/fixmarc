use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_511_ind1 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('511');
    foreach my $f (@flist) {
        my $ind = $f->indicator(1) . "";
        if ($ind !~ /^[01]/) {
            my $newind = "0";
            $f->set_indicator(1, $newind);
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="511"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="511"]/@ind1\') not in ("0", "1")',
    'func' => \&fix_511_ind1
                         });
$fixer->run();
