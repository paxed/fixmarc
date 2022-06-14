use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Muuttaa 999c:n samaksi kuin 999d

sub fix_999c {
    my ($fixer, $record) = @_;

    my @farr = $record->field('999');

    foreach my $f (@farr) {
        my $c = $f->subfield('c') || 0;
        my $d = $f->subfield('d') || 0;

        if ($c && $d && ($c != $d)) {
            $f->update('c' => $d);
            $fixer->msg("Changed 999c from \"$c\" to \"$d\"");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="999"]/subfield[@code="c"]\') != ExtractValue(metadata, \'//datafield[@tag="999"]/subfield[@code="d"]\')',
    'func' => \&fix_999c
                         });
$fixer->run();
