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

        my $p33 = substr($fdata, 33, 1);

        if ($p33 eq ' ') {
                $fdata = str_replace_nth($fdata, 33, '|');
                $f->update($fdata);
                $fixer->msg("Changed 008 '".$ofdata."'=>'".$fdata."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'substr(ExtractValue(metadata, \'//controlfield[@tag="008"]\'), 34, 1) = " "',
    'func' => \&fix_008
                         });
$fixer->run();
