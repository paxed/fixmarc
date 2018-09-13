use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub fix_024ind1 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('024');

    foreach my $f (@flist) {
        my $ind = $f->indicator(1) . "";

        if ($ind !~ /^[0123478]/) {
            my @sfa = $f->subfields();

            foreach my $sf (@sfa) {
                if ($sf->[0] eq 'a') {
                    my $tmpa = $sf->[1];
                    $tmpa =~ s/ //g;
                    if (length($tmpa) == 13 && $tmpa =~ m/^[0-9]+$/) {
                        my $newind = "3";
                        $f->set_indicator(1, $newind);
                        $fixer->msg("Changed ".$f->tag().".ind1:'".$ind."'=>'".$newind."'");
                    }
                }
            }
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield[@tag="024"])\') > 0 and ExtractValue(metadata, \'//datafield[@tag="024"]/@ind1\') not regexp \'^[0123478]\'',
    'func' => \&fix_024ind1
                         });
$fixer->run();
