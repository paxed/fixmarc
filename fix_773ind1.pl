use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_773_ind1 {
    my ($fixer, $record) = @_;
    # Do stuff here
    my @flist = $record->field('773');

    for my $f (@flist) {
        my $ind = $f->indicator(1) . "";
        if ($ind !~ /^[01]$/) {
            $f->set_indicator(1, "0");
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'0'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="773"])\') > 0 AND ExtractValue(metadata, \'//datafield[@tag="773"]/@ind1\') NOT REGEXP \'^[01]$\' ',
    'func' => \&fix_773_ind1
                         });
$fixer->run();
