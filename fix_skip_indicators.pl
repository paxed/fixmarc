use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub get_skipval {
    my ($s, $lang) = @_;

    my $ival = 0;
    my $addi = 0;

    if ($s =~ /^([^\w]+)/) {
        $addi = length($1);
        $s =~ s/^[^\w]+//;
    }

    if ($s =~ /^(The |An |A |L'|La |Le |Les |El |Il |Un |De |Det |Den |Ett |Das |Der )/i) {
        $ival = length($1);
    } elsif ($lang eq 'ger' && $s =~ /^(Die )/i) {
        $ival = length($1);
    } elsif ($lang eq 'swe' && $s =~ /^(En )/i) {
        $ival = length($1);
    }
    $ival += $addi;
    $ival = 0 if ($ival > 9);
    return $ival;
}

# in biblio records, fields and the indicator which is a skip characters
my %skip_ind_fields = (
    '130' => 1,
    '630' => 1,
    '730' => 1,
    '740' => 1,
    '222' => 2,
    '240' => 2,
    '242' => 2,
    '243' => 2,
    '245' => 2,
    # '440' => 2, Obsolete since 2008
    '830' => 2
    );

sub fix_skip_ind {
    my ($fixer, $record) = @_;

    my @fields = keys %skip_ind_fields;

    my $lang = '';
    my $f008 = $record->field('008');
    if (defined($f008)) {
        my $f008data = $f008->data();
        if (length($f008data) == 40) {
            $lang = lc(substr($f008data, 35, 3));
        }
    }

    foreach my $fnum (@fields) {
        my @flist = $record->field($fnum);
        my $indnum = $skip_ind_fields{$fnum};
        foreach my $f (@flist) {
            my $ind = $f->indicator($indnum) . "";
            my $s = $f->subfield('a');
            if ($s) {
                my $ival = get_skipval($s, $lang);

                if ($ind !~ /^[0-9]$/) {
                    $f->set_indicator($indnum, "".$ival);
                    $fixer->msg("Changed ".$f->tag().".ind".$indnum.":'".$ind."'=>'".$ival."' (".$s.")");
                } elsif ($ind != $ival) {
                    $fixer->error($f->tag().".ind".$indnum."=='".$ind."', should be '".$ival."'? (".$s.")");
                }
            }
        }
    }
}

my $fixer = FixMarc->new({ 'func' => \&fix_skip_ind });
$fixer->run();
