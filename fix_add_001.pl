use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Add field 001, if it's missing. The 001 value is the biblionumber.

sub fix_001 {
    my ($fixer, $record) = @_;

    my $bn = $fixer->{'id'};

    my $nf = MARC::Field->new('001', $bn);
    $record->insert_fields_ordered($nf);
    $fixer->msg("Added ".$nf->tag().":'".$nd."'");
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//controlfield[@tag="001"])\') = 0',
    'func' => \&fix_001
                         });
$fixer->run();
