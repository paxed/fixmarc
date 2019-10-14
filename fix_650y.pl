use utf8;
binmode STDOUT, ':utf8';

use strict;
use warnings;

#
# -for each 650y that do not contain 0-9 and is not empty
#   - query finto yso-paikat vocabulary, if found, move this to 650y
#       http://api.finto.fi/rest/v1/search?vocab=yso-paikat&query=it%C3%A4-uusimaa&lang=fi&fields=topConceptOf
#   - otherwise, report a warning
#
#
#


do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

use Data::Dumper;

use DBI;

my @skipwords = (
    'keskiaika',
    'medeltiden',
    'antiikki',
    'antiken',
    'ysa',
    'sa',
    );

sub fix_ucfirst {
    my $s = shift;
    my @a = split(/-/, $s);
    $s = join("-", map { ucfirst($_) } @a);
    return $s;
}

sub fix_650y {
    my ($fixer, $record) = @_;

    my @f650 = $record->field('650');

    if (scalar(@f650) > 0) {
        foreach my $f (@f650) {
            my @sfa = $f->subfields();
            my $w = '';
	    my $sfpos = 0;
	    my $replaceit = 0;
            foreach my $sf (@sfa) {
		$sfpos++;
		next if ($sf->[0] ne 'y');
                my $w = $sf->[1] || '';
		next if ($w eq '');

		my $newvalue = '';
		my $lcw = lc($w);

		next if (grep { $_ eq $lcw } @skipwords);
		next if ($lcw =~ /.+aika$/);
		next if ($lcw =~ /.+kausi$/);

		$newvalue = fix_ucfirst($w);
		$fixer->msg("CHANGE:\"$w\"=>\"".$newvalue."\"");
		$sf->[0] = 'z';
		$sf->[1] = $newvalue;
		$replaceit = 1;
		next;
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
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="650"]/subfield[@code="y"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="650"]/subfield[@code="y"]\') not regexp \'[0-9]\'',
    'func' => \&fix_650y
                         });
$fixer->run();
