use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

use Unicode::Normalize qw(NFC);

# Fix decomposed characters, eg
# "O" + "COMBINING DIAERESIS" is changed to "LATIN CAPITAL LETTER O WITH DIAERESIS"
sub fix_decomposed {
    my ($fixer, $record) = @_;

    # TODO: silly. mayde allow changing the record as xml string
    my @fields = $record->field('...');
    foreach my $f (@fields) {
        if ($f->tag() < 010) {
           my $s = NFC($f->data());
           $f->update($s);
        } else {
           my @sfa = $f->subfields();
           my $replaceit = 0;
           foreach my $sf (@sfa) {
              my $s = NFC($sf->[1]);
              if ($s ne $sf->[1]) {
                  $fixer->msg("Changed " . $f->tag() . $sf->[0]);
                  $replaceit = 1;
                  $sf->[1] = $s;
              }
           }
           if ($replaceit) {
               my $newf = new MARC::Field($f->tag(), $f->indicator(1), $f->indicator(2), '9' => '');
               $newf->delete_subfield('9');
               foreach my $tmpsf (@sfa) {
                   $newf->add_subfields($tmpsf->[0] => $tmpsf->[1]);
               }
               $f->replace_with($newf);
           }
        }
    }
}


my $fixer = FixMarc->new({
    'func' => \&fix_decomposed
                         });
$fixer->run();
