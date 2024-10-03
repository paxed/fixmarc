use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

#
# fix 007/02


sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    if ($nth < length($str)-1) {
        return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
    }
    return substr($str, 0, $nth).$chr;
}

sub fix_007_02 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('007');
    foreach my $f (@flist) {
        my $data = $f->data();
        my $odata = $data;
        if ( $data =~ /^[acdfghkmrsv]/ ) {
            next if (length($data) < 3);
            $data = str_replace_nth($data, 2, ' ');
            if ($data ne $odata) {
                $f->update($data);
                $fixer->msg("Changed ".$f->tag().":'".$odata."'=>'".$data."'");
            }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'substr(ExtractValue(metadata, \'//controlfield[@tag="007"]\'), 3, 1) != " "',
    'func' => \&fix_007_02
                         });
$fixer->run();
