use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

my %bibnum_to_773w;
my %f001f003_to_bibnum;

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub gather_data {
    my ($fixer, $record) = @_;

    my $f003 = $record->field('003');

    if (!defined($f003)) {
        $fixer->error("Missing 003");
        return;
    }
    $f003 = $f003->data();

    my @f001 = $record->field('001');

    if (scalar(@f001) == 0) {
        $fixer->error("Missing 001");
        return;
    } elsif (scalar(@f001) == 1) {
        # all OK
    } else {
        $fixer->error("Multiple 001");
        return;
    }

    if ($f003 ne trim($f003)) {
        $fixer->error("003 needs trimming (".$f003.")");
        $f003 = trim($f003);
    }

    my $f001data = $f001[0]->data();
    my @f773 = $record->field('773');
    my $bibnum = $fixer->{'id'}; # biblionumber

    if (scalar(@f773) > 0) {
        my $ldr7 = substr($record->leader(), 7, 1);
        if (!($ldr7 =~ /^[abcd]$/)) {
            $fixer->error("ldr/7 is $ldr7");
        }

        foreach my $f (@f773) {
            my @sfa = $f->subfields();
            my $w = '';

            foreach my $sf (@sfa) {
                $w = $sf->[1] if ($sf->[0] eq 'w');
            }

            if ($w ne '') {
                $bibnum_to_773w{$bibnum} = $w."\t".$f003;
                #$fixer->msg("773:".$w."-".$f003);
            }
        }
    }

    $f001f003_to_bibnum{$f001data."\t".$f003} = $bibnum;
    #$fixer->msg("001:".$f001data."-".$f003);
}

my $fixer = FixMarc->new({'func' => \&gather_data});
$fixer->run();

my $k;
my $v;
while (($k, $v) = each(%bibnum_to_773w)) {
    print "$k\n" if (!defined($f001f003_to_bibnum{$v}));
}
