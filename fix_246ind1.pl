use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_246_ind1 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('246');
    foreach my $f (@flist) {
        my $ind = $f->indicator(1) . "";
        if ($ind !~ /^[0123]/) {
            my $newind = "3";
            $f->set_indicator(1, $newind);
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="246"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="246"]/@ind1\') not in ("0", "1", "2", "3")',
    'func' => \&fix_246_ind1
                         });
$fixer->run();
