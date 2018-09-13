use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_add007_LE {
    my ($fixer, $record) = @_;

    my $nd = "sd |||||||p|||";
    my $nf = MARC::Field->new('007', $nd);

    $record->insert_fields_ordered($nf);
    $fixer->msg("Added ".$nf->tag().":'".$nd."'");
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "LE" and ExtractValue(metadata, \'count(//controlfield[@tag="007"])\') = 0',
    'func' => \&fix_add007_LE
                         });
$fixer->run();
