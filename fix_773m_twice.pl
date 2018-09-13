use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_773m_multiple {
    my ($fixer, $record) = @_;

    my @f773 = $record->field('773');
    if (scalar(@f773) > 0) {
        foreach my $f (@f773) {
            my @sfa = $f->subfields();
            my $count = 0;

            foreach my $sf (@sfa) {
                $count++ if ($sf->[0] eq 'm');
            }

            if ($count > 1) {
                $f->delete_subfield('m');
                $fixer->msg("Deleted multiple 773m");
            }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="773"]/subfield[@code="m"])\') > 1',
    'func' => \&fix_773m_multiple
                         });
$fixer->run();
