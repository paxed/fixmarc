use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;
    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub fix_ALEHTI {
    my ($fixer, $record) = @_;

    my $ldr = $record->leader();
    my $ldr67 = substr($ldr, 6, 2);
    my $new67;

    my @f773 = $record->field('773');

    if (scalar(@f773) > 0) {
        $new67 = "ab";
    } else {
        $new67 = "as";
    }

    if ($ldr67 ne $new67) {
        my $tmp = str_replace_nth($ldr, 6, $new67);
        $record->leader($tmp);
        $fixer->msg("Replaced ldr/6-7 '".$ldr67."'=>'".$new67."'");
    }

    my @f008 = $record->field('008');
    foreach my $f (@f008) {
        my $d = $f->data();
        my $nd = str_replace_nth($d, 21, 'p');
        if ($d ne $nd) {
            $f->update($nd);
            $fixer->msg("Changed ".$f->tag().":'".$d."'=>'".$nd."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "ALEHTI"',
    'func' => \&fix_ALEHTI
                         });
$fixer->run();
