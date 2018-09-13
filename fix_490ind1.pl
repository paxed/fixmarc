use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_490_ind1 {
    my ($fixer, $record) = @_;
    # Do stuff here
    my @f8xx = $record->field('80.');
    @f8xx = $record->field('81.') if (!scalar(@f8xx));
    @f8xx = $record->field('82.') if (!scalar(@f8xx));
    @f8xx = $record->field('83.') if (!scalar(@f8xx));

    my @flist = $record->field('490');
    foreach my $f (@flist) {
        my $ind = $f->indicator(1) . "";
        if ($ind ne "0" && $ind ne "1") {
            my $newind = scalar(@f8xx) ? "1" : "0";
            $f->set_indicator(1, $newind);
            $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'".$newind."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="490"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="490"]/@ind1\') not in ("0", "1")',
    'func' => \&fix_490_ind1
                         });
$fixer->run();
