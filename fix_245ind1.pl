use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_245_ind1 {
    my ($fixer, $record) = @_;

    my @f1xx = $record->field('1..');
    my @flist = $record->field('245');
    foreach my $f (@flist) {
        my $ind = $f->indicator(1) . "";
        if ($ind ne "0" && $ind ne "1") {
            my $newind = scalar(@f1xx) ? "1" : "0";
            $f->set_indicator(1, $newind);
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="245"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="245"]/@ind1\') not in ("0", "1")',
    'func' => \&fix_245_ind1
                         });
$fixer->run();
