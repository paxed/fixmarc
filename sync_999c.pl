use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Muuttaa 999d:n samaksi kuin 999c

sub fix_999c {
    my ($fixer, $record) = @_;

    my @farr = $record->field('999');

    foreach my $f (@farr) {
        my $c = $f->subfield('c') || 0;
        my $d = $f->subfield('d') || 0;

        if ($c && $d && ($c != $d)) {
            $f->update('d' => $c);
            $fixer->msg("Changed 999d from \"$d\" to \"$c\"");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="999"]/subfield[@code="c"]\') != ExtractValue(metadata, \'//datafield[@tag="999"]/subfield[@code="d"]\')',
    'func' => \&fix_999c
                         });
$fixer->run();
