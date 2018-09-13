use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_655_ind2 {
    my ($fixer, $record) = @_;

    my @f655 = $record->field('655');
    foreach my $f (@f655) {
        my $sf_2 = $f->subfield('2') || undef;
	my @sfs = $f->subfields();
        my $ind2 = $f->indicator(2) || "";

        if (defined($sf_2) && $ind2 eq " " && scalar(@sfs) > 1) {
            $f->set_indicator(2, "7");
            $fixer->msg("Changed ".$f->tag().".ind2:'".$ind2."'=>'7'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="655" and @ind2=" "])\') > 0',
    'func' => \&fix_655_ind2
                         });
$fixer->run();
