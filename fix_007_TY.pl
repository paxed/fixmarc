use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_007_TY {
    my ($fixer, $record) = @_;

    my $nd = 'kl |||';

    my @flist = $record->field('007');
    if (scalar(@flist) == 0) {
        my $nf = MARC::Field->new('007', $nd);
        $record->insert_fields_ordered($nf);
        $fixer->msg("Added ".$nf->tag().":'".$nd."'");
    } else {
        foreach my $f (@flist) {
            my $data = $f->data();
            if ( $data ne $nd || $data eq '' ) {
                $f->update($nd);
                $fixer->msg("Changed ".$f->tag().":'".$data."'=>'".$nd."'");
            }
        }
    }
}


my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "TY"',
    'func' => \&fix_007_TY
                         });
$fixer->run();
