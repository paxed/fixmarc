use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_100ind1 {
    my ($fixer, $record) = @_;

    my @f100 = $record->field('100');
    foreach my $f (@f100) {
        my $ind1 = $f->indicator(1) || " ";

        if ($ind1 !~  /^[013]$/) {
            my $val = $f->subfield('a');
            if (!defined($val)) {
                $fixer->msg("ERROR: 100a not set");
                next;
            } elsif ($val =~ /, /) {
                $f->set_indicator(1, "1");
                $ind1 = "1";
            } else {
                $f->set_indicator(1, "0");
                $ind1 = "0";
            }
            $fixer->msg("Changed 100.ind1:'".$ind1."':'".$val."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="100"])\') > 0',
    'func' => \&fix_100ind1
                         });
$fixer->run();
