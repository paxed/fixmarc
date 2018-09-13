use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_830_ind2 {
    my ($fixer, $record) = @_;

    my $field = '830';
    my $indic = 2;
    my $defval = "0";
    my @flist = $record->field($field);

    foreach my $f (@flist) {
        my $ind = $f->indicator($indic) . "";

        if ($ind !~ /^[0-9]$/) {
            $f->set_indicator($indic, $defval);
            $fixer->msg("Changed ".$f->tag().".ind".$indic.":'".$ind."'=>'".$defval."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="830"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="830"]/@ind2\') not regexp \'^[0-9]\'',
    'func' => \&fix_830_ind2
                         });
$fixer->run();
