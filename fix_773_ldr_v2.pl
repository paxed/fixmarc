use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    if ($nth < length($str)-1) {
        return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
    }
    return substr($str, 0, $nth).$chr;
}

sub fix_773_ldr {
    my ($fixer, $record) = @_;

    my $ldr = $record->leader();
    my $ldr7 = substr($ldr, 7, 1);
    my @f773 = $record->field('773');

    if (scalar(@f773) == 0 && $ldr7 =~ /^[abd]$/) {
        my $tmp = str_replace_nth($ldr, 7, 'm');
        $record->leader($tmp);
        $fixer->msg("Replaced ldr/7 '".$ldr7."'=>'m'");
    }
}

my $fixer = FixMarc->new({
    'sql' => 'SELECT bm.biblionumber, bm.metadata, bm.timestamp
FROM biblio_metadata bm LEFT JOIN items i ON bm.biblionumber=i.biblionumber
WHERE ExtractValue(bm.metadata,\'//datafield[@tag="773"]/subfield[@code="w"]\') = ""
AND i.itemnumber IS NOT NULL
AND SUBSTR(ExtractValue(bm.metadata,\'//leader\'),8,1) IN ("a", "b", "d")
',
    'func' => \&fix_773_ldr
                         });
$fixer->run();
