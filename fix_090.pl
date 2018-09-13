use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_090 {
    my ($fixer, $record) = @_;

    my @f090 = $record->field('090');
    $record->delete_fields(@f090);
    $fixer->msg("Deleted 090");
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="090"])\') > 0',
    'func' => \&fix_090
                         });
$fixer->run();
