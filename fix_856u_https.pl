use utf8;
binmode STDOUT, ':utf8';

use strict;
use warnings;

# Change all 856u http: => https:

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

use Data::Dumper;

use DBI;


sub fix_856u {
    my ($fixer, $record) = @_;

    my @f856 = $record->field('856');

    if (scalar(@f856) > 0) {
        foreach my $f (@f856) {
            my @sfa = $f->subfields();
	    my $replaceit = 0;
            foreach my $sf (@sfa) {
		next if ($sf->[0] ne 'u');
                my $w = $sf->[1];
                $w =~ s/\bhttp:/https:/;
                if ($w ne $sf->[1]) {
                    $replaceit = 1;
                    $sf->[1] = $w;
                }
	    }

	    if ($replaceit) {
		my $newfield = new MARC::Field($f->tag(), $f->indicator(1), $f->indicator(2), '9' => '');
		$newfield->delete_subfield('9');
		foreach my $tmpsf (@sfa) {
		    $newfield->add_subfields($tmpsf->[0] => $tmpsf->[1]);
		}
		$f->replace_with($newfield);
	    }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'//datafield[@tag="856"]/subfield[@code="u"]\') like "%http:%"',
    'func' => \&fix_856u
                         });
$fixer->run();
