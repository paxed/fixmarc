use strict;
use warnings;

# Fix the following:
#  008-BK/18-21
#  008-BK/24-27
#  008-BK/29
#  008-BK/30
#  008-BK/31

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub str_replace_nth {
    my ($str, $nth, $chr) = @_;
    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub xch {
    my ($fixer, $ofdata, $startidx, $len, $allowchars) = @_;
    my $fdata = $ofdata;
    my $s = substr($fdata, $startidx, $len);
    my $os = $s;

    $s =~ s/\|/ /g;
    $s =~ s/[^\Q$allowchars\E]/ /g;
    $s = trim($s);
    $s = "|" x $len if ($s eq '');
    $s = sprintf("%-".$len."s", $s);
    $fdata = str_replace_nth($fdata, $startidx, $s);
    $fixer->msg("Update 008/".$startidx."-".($startidx+$len-1).":'".$os."'=>'".$s."'") if ($os ne $s);
    return $fdata;
}

sub fix_008 {
    my ($fixer, $record) = @_;

    my $ldr6 = substr($record->leader(), 6, 1);

    return if (!($ldr6 =~ /^[cdij]$/));

    my @flist = $record->field('008');

    foreach my $f (@flist) {
        my $fdata = $f->data();
        my $ofdata = $fdata;

        next if (length($fdata) != 40);

	if ($fdata =~ /^([0-9]{6}| {6})(.)(....)(....)(...)(..)(.)(.)(.)(.)(......)(..)(.)(.)(.)(...)(.)(.)$/) {
	    my $createdate = $1; # 00-05
	    my $pubtype = $2;    # 06
	    my $pubdate1 = $3;   # 07-10
	    my $pubdate2 = $4;   # 11-14
	    my $pubcountry = $5; # 15-17

            my $genre = $6;      # 18-19
            my $format = $7;     # 20
            my $voices = $8;     # 21
            my $targetaud = $9;  # 22
            my $itemform = $10;  # 23
            my $accomp = $11;    # 24-29
            my $littext = $12;   # 30-31
            my $unknown1 = $13;  # 32
            my $transpon = $14;  # 33
            my $unknown2 = $15;  # 34

	    my $lang = $16;      # 35-37
	    my $modded = $17;    # 38
	    my $catsrc = $18;    # 39

            if ($genre eq '  ') {
                my $s = "||";
                $fdata = str_replace_nth($fdata, 18, $s);
                $fixer->msg("Update 008/18-19:'".$genre."'=>'".$s."'");
            }

            $fdata = xch($fixer, $fdata, 24, 6, " abcdefghikrsz");

            $fdata = xch($fixer, $fdata, 30, 2, " abcdefghijklmnoprstz") if ($littext ne '  ');

            if ($transpon !~ /[ abcnu\|]/) {
                my $s = "|";
                $fdata = str_replace_nth($fdata, 33, $s);
                $fixer->msg("Update 008/33:'".$transpon."'=>'".$s."'");
            }

	    $f->update($fdata) if ($fdata ne $ofdata);
	}
    }
}

my $fixer = FixMarc->new({
    'where' => 'substr(ExtractValue(metadata, \'//leader\'),7,1) in ("c", "d", "i", "j")',
    'func' => \&fix_008
                         });
$fixer->run();
