use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_028ind12_CA {
    my ($fixer, $record) = @_;

    my @flist = $record->field('028');
    foreach my $f (@flist) {
        my $ind1 = $f->indicator(1) . "";
        my $ind2 = $f->indicator(2) . "";
        if ($ind1 ne '6' and $ind2 ne '0') {
            $f->set_indicator(1, '6');
            $f->set_indicator(2, '0');
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind1."'=>'6', ind2:'".$ind2."'=>'0'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "CA"',
    'func' => \&fix_028ind12_CA
                         });
$fixer->run();
