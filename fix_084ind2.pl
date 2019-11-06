use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

my $inum = 2;

sub fix_084_ind2 {
    my ($fixer, $record) = @_;
    # Do stuff here
    my @flist = $record->field('084');

    for my $f (@flist) {
        my $ind = $f->indicator($inum) . "";
        if ($ind !~ /^ $/) {
            $f->set_indicator($inum, " ");
            $fixer->msg("Changed ".$f->tag().".ind".$inum.":'".$ind."'=>' '");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="084"])\') > 0 AND ExtractValue(metadata, \'//datafield[@tag="084"]/@ind'.$inum.'\') != " " ',
    'func' => \&fix_084_ind2
                         });
$fixer->run();
