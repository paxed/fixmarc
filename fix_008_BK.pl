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

sub fix_008 {
    my ($fixer, $record) = @_;

    my $ldr67 = substr($record->leader(), 6, 2);

    # ldr/6 == a OR t, AND ldr/7 != b OR i OR s
    return if (!($ldr67 =~ /^[at][^bis]$/)); # BK only

    my @flist = $record->field('008');

    foreach my $f (@flist) {
        my $fdata = $f->data();
        my $ofdata = $fdata;

        next if (length($fdata) != 40);

	if ($fdata =~ /^([0-9]{6}| {6})(.)(....)(....)(...)(....)(.)(.)(....)(.)(.)(.)(.)(.)(.)(.)(...)(.)(.)$/) {
	    my $createdate = $1; # 00-05
	    my $pubtype = $2;    # 06
	    my $pubdate1 = $3;   # 07-10
	    my $pubdate2 = $4;   # 11-14
	    my $pubcountry = $5; # 15-17
	    my $illos = $6;      # 18-21
	    my $targetaud = $7;  # 22
	    my $itemform = $8;   # 23
	    my $contents = $9;   # 24-27
	    my $govtpub = $10;   # 28
	    my $confpub = $11;   # 29
	    my $fest = $12;      # 30
	    my $index = $13;     # 31
	    my $undef1 = $14;    # 32
	    my $litform = $15;   # 33
	    my $biogr = $16;     # 34
	    my $lang = $17;      # 35-37
	    my $modded = $18;    # 38
	    my $catsrc = $19;    # 39

	    if ($illos !~ /^([abcdefghijklmop]* *|\|\|\|\|)$/) {
		my $s = $illos;
		$s =~ s/\|/ /g;
		$s =~ s/[^ abcdefghijklmop]/ /g;
		$s = trim($s);
		$s = "||||" if ($s eq '');
		$s = sprintf("%-4s", $s);
		$fdata = str_replace_nth($fdata, 18, $s);
		$fixer->msg("Update 008/18-21: '".$illos."'=>'".$s."'") if ($s ne $illos);
	    }

	    if ($contents !~ /^([abcdefgijklmnopqrstuvwyz256]* *|\|\|\|\|)$/) {
		my $s = $contents;
		$s =~ s/\|/ /g;
		$s =~ s/[^ abcdefgijklmnopqrstuvwyz256]/ /g;
		$s = trim($s);
		$s = "||||" if ($s eq '');
		$s = sprintf("%-4s", $s);
		$fdata = str_replace_nth($fdata, 24, $s);
		$fixer->msg("Update 008/24-27: '".$contents."'=>'".$s."'") if ($s ne $contents);
	    }

            if ($confpub !~ /[01\|]/) {
                my $s = "|";
                $fdata = str_replace_nth($fdata, 29, $s);
		$fixer->msg("Update 008/29: '".$confpub."'=>'".$s."'");
            }

            if ($fest !~ /[01\|]/) {
                my $s = "|";
                $fdata = str_replace_nth($fdata, 30, $s);
		$fixer->msg("Update 008/30: '".$fest."'=>'".$s."'");
            }

            if ($index !~ /[01\|]/) {
                my $s = "|";
                $fdata = str_replace_nth($fdata, 31, $s);
		$fixer->msg("Update 008/31: '".$index."'=>'".$s."'");
            }

	    $f->update($fdata) if ($fdata ne $ofdata);
	}
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//controlfield[@tag="008"])\') > 0',
    'func' => \&fix_008
                         });
$fixer->run();
