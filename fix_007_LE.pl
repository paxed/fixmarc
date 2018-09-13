use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_007_LE {
    my ($fixer, $record) = @_;

    my @flist = $record->field('007');
    foreach my $f (@flist) {
        my $data = $f->data();
        if ( $data =~ /^su/ || $data eq '' ) {
            my $nd = "sd |||||||p|||";
            $f->update($nd);
            $fixer->msg("Changed ".$f->tag().":'".$data."'=>'".$nd."'");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "LE" AND ExtractValue(metadata, \'count(//controlfield[@tag="007"])\') > 0',
    'func' => \&fix_007_LE
                         });
$fixer->run();
