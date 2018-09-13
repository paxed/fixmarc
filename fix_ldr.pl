use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_ldr {
    my ($fixer, $record) = @_;

    my $ldr = $record->leader();
    my $ldro = $ldr;
    if ($ldr =~ /^(....................4500) /) {
        $ldr = $1;
        $record->leader($ldr);
        $fixer->msg("Trimmed leader end ('$ldro'->'$ldr')");
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'string-length(//leader)\') != 24',
    'func' => \&fix_ldr
                         });
$fixer->run();
