use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_007_CDM {
    my ($fixer, $record) = @_;

    my $nd = "sd f||g|||m|||";

    my @flist = $record->field('007');
    if (scalar(@flist) == 0) {
        my $nf = MARC::Field->new('007', $nd);
        $record->insert_fields_ordered($nf);
        $fixer->msg("Added ".$nf->tag().":'".$nd."'");
    } else {
        foreach my $f (@flist) {
            my $data = $f->data();
            if ( $data =~ /^su/ || $data eq '' ) {
                $f->update($nd);
                $fixer->msg("Changed ".$f->tag().":'".$data."'=>'".$nd."'");
            }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "CDM"',
    'func' => \&fix_007_CDM
                         });
$fixer->run();
