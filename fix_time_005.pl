use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Fix 005 by adding the time part to it

sub fix_time_005 {
    my ($fixer, $record) = @_;

    my $f005 = $record->field('005');
    if (defined($f005)) {
        my $ts = $f005->data();
        my $nts = $ts . "000000.0";
        $f005->update($nts);
        $fixer->msg("Changed ".$f005->tag().":'".$ts."'=>'".$nts."'");
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'string-length(//controlfield[@tag="005"])\') = 8',
    'func' => \&fix_time_005
                         });
$fixer->run();
