use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_500_multiples {
    my ($fixer, $record) = @_;

    my @flist = $record->field('500');
    foreach my $f (@flist) {
        my @sfa = $f->subfields();
        my @alist = ();

        foreach my $sf (@sfa) {
            push(@alist, $sf->[1]) if ($sf->[0] eq 'a');
        }
        if (scalar(@alist) > 1) {
            $record->delete_fields($f);
            my @tmparr;
            foreach my $aval (@alist) {
                push(@tmparr,  MARC::Field->new('500', $f->indicator(1), $f->indicator(2), 'a' => $aval));
            }
            $record->insert_fields_ordered(@tmparr);
            $fixer->msg("Split repeated 500a into multiple 500");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="500"]/subfield[@code="a"])\') > 1',
    'func' => \&fix_500_multiples
                         });
$fixer->run();
