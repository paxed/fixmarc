use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_700_ind1 {
    my ($fixer, $record) = @_;

    my $changed = 0;
    my @flist = $record->field('700');

    foreach my $f (@flist) {
        my $ind1 = $f->indicator(1) || " ";

        if ($ind1 !~ /^[013]$/) {
            my @sfa = $f->subfields();
            foreach my $sf (@sfa) {
                if ($sf->[0] eq 'a') {
                    if ($sf->[1] =~ /, /) {
                        $f->set_indicator(1, "1");
                        $changed = 1;
                    }
                }
                last if ($changed);
            }
        }
    }
    printmsg("Changed", $id) if ($changed);
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="700"]/subfield[@code="a"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="700"]/@ind1\') not in ("0", "1", "3")',
    'func' => \&fix_700_ind1
                         });
$fixer->run();
