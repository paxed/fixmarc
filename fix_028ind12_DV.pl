use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_028ind12_DV {
    my ($fixer, $record) = @_;

    my @flist = $record->field('028');
    foreach my $f (@flist) {
        my $ind1 = $f->indicator(1) . "";
        my $ind2 = $f->indicator(2) . "";
        if ($ind1 ne '4' and $ind2 ne '2') {
            $f->set_indicator(1, '4');
            $f->set_indicator(2, '2');
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind1."'=>'4', ind2:'".$ind2."'=>'2'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "DV"',
    'func' => \&fix_028ind12_DV
                         });
$fixer->run();
