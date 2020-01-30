use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub check_dblspaces {
    my ($fixer, $record) = @_;

    my @fields = $record->field('...');
    foreach my $f (@fields) {
        if ($f->tag() < 010) {
            my $s = $f->data();
            $fixer->msg("Multiple spaces in ".$f->tag()." (".$s.")") if ($s =~ /  /);
        } else {
            my @sfa = $f->subfields();
            foreach my $sf (@sfa) {
                my $s = $sf->[1];
                $fixer->msg("Multiple spaces in ".$f->tag()."\$".$sf->[0]." (".$s.")") if ($s =~ /  /);
            }
        }
    }
}


my $fixer = FixMarc->new({
    'func' => \&check_dblspaces
                         });
$fixer->run();
