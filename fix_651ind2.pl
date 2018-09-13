use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_651_ind2 {
    my ($fixer, $record) = @_;

    my $field = '651';
    my $indic = 2;
    my @flist = $record->field($field);

    foreach my $f (@flist) {
        my $ind = $f->indicator($indic) . "";
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
            $f->set_indicator($indic, $newind);
            $fixer->msg("Changed ".$f->tag().".ind".$indic.":'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="651"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="651"]/@ind2\') not regexp \'^[0-7]\'',
    'func' => \&fix_651_ind2
                         });
$fixer->run();
