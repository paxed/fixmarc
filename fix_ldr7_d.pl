use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;
    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub fix_ldr7_d {
    my ($fixer, $record) = @_;
    # Do stuff here
    my $ldr = $record->leader();
    my $ldr7 = substr($ldr, 7, 1);

    if ($ldr7 eq 'd') {
        my $tmp = str_replace_nth($ldr, 7, 'a');
        $record->leader($tmp);
        $fixer->msg("Replaced ldr/7 'd'=>'a'");
    }
}

my $fixer = FixMarc->new({
    'where' => 'SUBSTRING(ExtractValue(metadata, \'//leader\'),8,1) = \'d\'',
    'func' => \&fix_ldr7_d
                         });
$fixer->run();
