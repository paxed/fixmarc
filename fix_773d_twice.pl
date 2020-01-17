use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_773d_multiple {
    my ($fixer, $record) = @_;

    my @f773 = $record->field('773');
    if (scalar(@f773) > 0) {
        foreach my $f (@f773) {
            my @sfa = $f->subfields();
            my $d = '';

            foreach my $sf (@sfa) {
                if ($sf->[0] eq 'd') {
                    if ($sf->[1] =~ /(18|19|20)\d\d/) {
                        $d = $d . $sf->[1];
                    } else {
                        $d = $sf->[1] . $d;
                    }
                }
            }
            if ($d ne '') {
                $f->delete_subfield('d');
                $f->add_subfields('d' => $d);
                $fixer->msg("Merged 773d to '".$d."'");
            }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="773"]/subfield[@code="d"])\') > 1',
    'func' => \&fix_773d_multiple
                         });
$fixer->run();
