use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;
    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub fix_773_ldr {
    my ($fixer, $record) = @_;
    # Do stuff here
    my $ldr = $record->leader();
    my $ldr7 = substr($ldr, 7, 1);
    my @f773 = $record->field('773');

    if (scalar(@f773) > 0 && $ldr7 eq 'm') {
        my $tmp = str_replace_nth($ldr, 7, 'a');
        $record->leader($tmp);
        $fixer->msg("Replaced ldr/7 'm'=>'a'");
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="773"])\') > 0 and SUBSTRING(ExtractValue(metadata, \'//leader\'),8,1) = \'m\'',
    'func' => \&fix_773_ldr
                         });
$fixer->run();
