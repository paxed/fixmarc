use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;
    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub fix_008 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('008');

    foreach my $f (@flist) {
        my $fdata = $f->data();
        my $ofdata = $fdata;

        next if (length($fdata) != 40);
        my $p06 = substr($fdata, 06, 1);

        if ($p06 !~ /[bcdeikmnpqrstu|]/) {
                $fdata = str_replace_nth($fdata, 06, '|');
                $f->update($fdata);
                $fixer->msg("Changed 008 '".$ofdata."'=>'".$fdata."'");
        }
    }
}

my $fixer = FixMarc->new({
    'func' => \&fix_008
                         });
$fixer->run();
