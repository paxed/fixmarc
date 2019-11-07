use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_630_ind2 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('630');
    foreach my $f (@flist) {
        my $ind = $f->indicator(2) . "";
        my $has2 = 0;
        my $newind = "";

        my @sfa = $f->subfields();
        foreach my $sf (@sfa) {
            if ($sf->[0] eq '2') {
                $has2 = 1;
                last;
            }
        }
        if ($ind !~ /^[0-7]$/) {
            $newind = $has2 ? "7" : "4";
            $f->set_indicator(2, $newind);
            $fixer->msg("Changed 630.ind2:'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="630"])\') > 0',
    'func' => \&fix_630_ind2
                         });
$fixer->run();
