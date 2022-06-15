use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Muuttaa 999d:n ja 999c:n samaksi kuin biblio_metadata.biblionumber

sub fix_999_bn {
    my ($fixer, $record) = @_;

    my @farr = $record->field('999');
    my $id = $fixer->{'id'};

    foreach my $f (@farr) {
        my $c = $f->subfield('c') || 0;
        my $d = $f->subfield('d') || 0;

        if ($c && $c != $id) {
            $f->update('c' => $id);
            $fixer->msg("Changed 999c from \"$c\" to \"$id\"");
        }
        if ($d && $d != $id) {
            $f->update('d' => $id);
            $fixer->msg("Changed 999d from \"$d\" to \"$id\"");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="999"]/subfield[@code="c"]\') != biblionumber or ExtractValue(metadata, \'//datafield[@tag="999"]/subfield[@code="d"]\') != biblionumber',
    'func' => \&fix_999_bn
                         });
$fixer->run();
