use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

#
# fix some errors in 007 sound recordings (when /01==s)
# replaces illegal chars with '|' in certain locations


sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    if ($nth < length($str)-1) {
        return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
    }
    return substr($str, 0, $nth).$chr;
}

sub test_str_replace_nth {
    print str_replace_nth("ABC", 0, "x")."\n";
    print str_replace_nth("ABC", 1, "x")."\n";
    print str_replace_nth("ABC", 2, "x")."\n";
    print str_replace_nth("ABC", 3, "x")."\n";
    print str_replace_nth("ABC", 4, "x")."\n";
    exit;
}

sub replace_ch_at {
    my ($f, $pos, $valid) = @_;

    my $data = $f->data();
    my $ch = substr($data, $pos, 1);
    if ($ch ne '|' && $ch !~ $valid) {
        $data = str_replace_nth($data, $pos, '|');
        $f->update($data);
    }
}

sub fix_007_s {
    my ($fixer, $record) = @_;

    my @flist = $record->field('007');
    foreach my $f (@flist) {
        my $data = $f->data();
        my $odata = $data;
        my $ch;
        if ( $data =~ /^s/ ) {
            if (length($data) < 13) {
                while (length($data) < 13) { $data = $data . "|"; }
                $f->update($data);
            }

            replace_ch_at($f,  4, q/[mqsuz]/);
            replace_ch_at($f,  5, q/[mnsuz]/);
            replace_ch_at($f,  7, q/[lmnopuz]/);
            replace_ch_at($f,  8, q/[abcdefnuz]/);
            replace_ch_at($f,  9, q/[abdimnrstuz]/);
            replace_ch_at($f, 11, q/[hlnu]/);
            replace_ch_at($f, 12, q/[abcdefghnuz]/);
            replace_ch_at($f, 13, q/[abdeuz]/);

            $data = $f->data();
            $fixer->msg("Changed ".$f->tag().":'".$odata."'=>'".$data."'") if ($data ne $odata);
        }
    }
}

my $fixer = FixMarc->new({
    'where' => 'substr(ExtractValue(metadata, \'//controlfield[@tag="007"]\'), 1, 1) = "s"',
    'func' => \&fix_007_s
                         });
$fixer->run();
