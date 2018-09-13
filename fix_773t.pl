use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

use DBI;

sub fix_773t {
    my ($fixer, $record) = @_;

    my $changed = 0;

    my $f003 = $record->field('003');
    if (!defined($f003)) {
        $fixer->error("Missing 003");
        return;
    }

    my $f003data = $f003->data();
    my @f773 = $record->field('773');

    if (scalar(@f773) > 0) {
        foreach my $f (@f773) {
            my @sfa = $f->subfields();
            my $w = '';
            my $newt = '';

            foreach my $sf (@sfa) {
                $w = $sf->[1] if ($sf->[0] eq 'w');
            }
            if ($w ne '') {
                my $newt = '';

                $w =~ s/\. -$//;

                $fixer->msg("Looking for $w");
                if (!defined($f001003{$w . $f003data})) {
                    my $sql = 'select biblionumber, ExtractValue(metadata, \'//datafield[@tag="245"]/subfield[@code="a"]\') as f245a from biblio_metadata where ExtractValue(metadata, \'//controlfield[@tag="001"]\') = ? and ExtractValue(metadata, \'//controlfield[@tag="003"]\') = ?';

                    my $sth = $dbh->prepare($sql);
                    $sth->execute($w, $f003data);
                    my $ref = $sth->fetchrow_hashref();
                    $newt = $ref->{'f245a'} || '';
                    if (defined($ref->{'biblionumber'})) {
                        $fixer->msg("Found bib ".$ref->{'biblionumber'}." ($newt)");
                        $f001003{$w . $f003data} = $newt;
                    } else {
                        $fixer->msg("Not found ($w, $f003data)");
                        $f001003{$w . $f003data} = '';
                    }
                } else {
                    $newt = $f001003{$w . $f003data};
                }

                if ($newt ne '') {
                    $f->add_subfields('t' => $newt);
                    $changed = 1;
                    $fixer->msg("Added 773t");
                }
            }
            last if ($changed);
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="773"])\') > 0 and ExtractValue(metadata, \'count(//datafield[@tag="773"]/subfield[@code="t"])\') = 0',
    'func' => \&fix_773t
                         });
$fixer->run();
