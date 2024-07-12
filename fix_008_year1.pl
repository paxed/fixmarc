use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;
    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub fix_008 {
    my ($fixer, $record) = @_;

    my @flist = $record->field('008');

    foreach my $f (@flist) {
        my $fdata = $f->data();
        my $ofdata = $fdata;

        if ($fdata =~ /^([0-9]{6})(.)(....)(....)/) {
            my $createdate = $1;
            my $pubtype = $2;
            my $year1 = $3;
            my $year2 = $4;

            if ($year1 eq '||||') {
                # it's good
            } elsif ($year1 !~ /^\d\d\d\d$/) {
                my $good = 0;
                my $f260 = $record->field('260');
                if ($f260) {
                    my $f260c = $f260->subfield('c') || '';
                    $f260c =~ s/[^0-9]//g;
                    if ($f260c =~ /^\d\d\d\d$/) {
                        $fdata = str_replace_nth($fdata, 7, $f260c);
                        $year1 = $f260c;
                        $good = 1;
                    }
                }

                if (!$good) {
                    if (lc($year1) eq 's.a.' || lc($year1) eq 'cop.') {
                        $year1 = ($pubtype eq 'b') ? '    ' : 'uuuu';
                        $fdata = str_replace_nth($fdata, 7, $year1);
                    } elsif ($year1 !~ /^\d[^\d][^\d][^\d]$/) {
                        $year1 =~ s/\?/u/g;
                        $fdata = str_replace_nth($fdata, 7, $year1);
                    } else {
                        $fixer->msg("year1:[$year1]");
                    }
                }
            }

            if ($year1 =~ /^\d\d\d\d$/ && $year2 =~ /^    $/) {
                $fdata = str_replace_nth($fdata, 6, 's');
            } elsif ($year1 =~ /^    $/ && $year2 =~ /^    $/) {
                $fdata = str_replace_nth($fdata, 6, 'b');
            }

            if ($ofdata ne $fdata) {
                $f->update($fdata);
            }
        } else {
            #$fixer->msg("MISMATCH 008:[$fdata]");
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//controlfield[@tag="008"])\') > 0 and SUBSTRING(ExtractValue(metadata, \'//controlfield[@tag="008"]\'), 8, 4) NOT REGEXP "^([0-9u]{4}|    )$"',
    'func' => \&fix_008
                         });
$fixer->run();
