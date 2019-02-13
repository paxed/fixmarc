use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub fix_trim_003 {
    my ($fixer, $record) = @_;

    my @fa003 = $record->field('003');
    if (scalar(@fa003) == 0) {
        $fixer->error("Missing 003");
        return;
    }

    foreach my $f003 (@fa003) {
        my $f003data = $f003->data();
        my $t = trim($f003data);
        if ($f003data ne '' && $f003data ne $t ) {
            $fixer->msg("Trimmed 003 (".$f003data.")=(".$t.")");
            $f003->update($t);
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'metadata regexp \'<controlfield tag="003">( +[^<]+|[^<]+ +)</controlfield>\'',
    'func' => \&fix_trim_003
                         });
$fixer->run();
