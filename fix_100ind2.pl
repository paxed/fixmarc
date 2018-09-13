use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_100ind2 {
    my ($fixer, $record) = @_;

    my @f100 = $record->field('100');
    foreach my $f (@f100) {
        my $ind2 = $f->indicator(2) || "";

        if ($ind2 ne " ") {
            $f->set_indicator(2, " ");
            $fixer->msg("Changed 100.ind2:'".$ind2."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="100"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="100"]/@ind2\') != " "',
    'func' => \&fix_100ind2
                         });
$fixer->run();
