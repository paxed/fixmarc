use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

my $WHERESQL = 'biblionumber in (select distinct biblionumber from items where itype = "CA")';
#my $WHERESQL = 'ExtractValue(metadata, \'//datafield[@tag="942"]/subfield[@code="c"]\') = "CELIA"',


sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub add_599a_celia {
    my ($fixer, $record) = @_;

    my $gotit = 0;

    my @f599 = $record->field('599');
    foreach my $f (@f599) {
        my @sfa = $f->subfields();
        foreach my $sf (@sfa) {
            next if ($sf->[0] ne 'a');
            $gotit = 1 if ($sf->[1] =~ /daisy/i)
        }
    }

    if (!$gotit) {
        my $fld = MARC::Field->new('599', ' ', ' ', 'a' => 'Daisy');
        $record->insert_fields_ordered($fld);
        $fixer->msg("Added 599a=Daisy");
    } else {
        $fixer->msg("599a with daisy already exists");
    }
}


my $fixer = FixMarc->new({
    'where' => $WHERESQL,
    'func' => \&add_599a_celia
                         });
$fixer->run();
