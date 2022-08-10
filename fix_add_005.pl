use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

use POSIX qw(strftime);

# Add field 005, if it's missing. The 005 value is biblio_metadata.timestamp

sub add_missing_005 {
    my ($fixer, $record) = @_;

    my $ts = $fixer->{'timestamp'};

    if (defined($ts)) {
        # Assume timestamp field from SQL is "YYYY-MM-DD HH:MM:SS"
        $ts =~ s/[^0-9]//g;
        $ts .= ".0"; # tenths of a second
        my $nf = MARC::Field->new('005', $ts);
        $record->insert_fields_ordered($nf);
        $fixer->msg("Added ".$nf->tag().":'".$ts."'");
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//controlfield[@tag="005"])\') = 0',
    'func' => \&add_missing_005
                         });
$fixer->run();
