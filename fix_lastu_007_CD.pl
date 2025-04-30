use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    if ($nth < length($str)-1) {
        return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
    }
    return substr($str, 0, $nth).$chr;
}


# Kenttään 007/03 arvo "f"
# Kenttään 007/06 arvo "g"
# Kenttä 007/13 ei koodatuksi, pystyviiva "|"


sub fix_lastu_007_CD {
    my ($fixer, $record) = @_;

    my @flist = $record->field('007');
    if (scalar(@flist) == 0) {
        $fixer->error("Missing 007");
    } else {
        foreach my $f (@flist) {
            my $data = $f->data();

            if ($data !~ /^sd/) {
                $fixer->error($f->tag().":'".$data."'");
                next;
            }

            my $nd = $data;

            $nd = str_replace_nth($nd, 02, ' ');
            $nd = str_replace_nth($nd, 03, 'f');
            $nd = str_replace_nth($nd, 06, 'g');
            $nd = str_replace_nth($nd, 13, '|');

            if ($nd ne $data) {
                $f->update($nd);
                $fixer->msg("Changed ".$f->tag().":'".$data."'=>'".$nd."'");
            }
        }
    }
}

my $fixer = FixMarc->new({
    'sql' => 'SELECT bm.biblionumber, bm.metadata, bm.timestamp FROM biblio_metadata bm LEFT JOIN biblioitems bi ON (bi.biblionumber=bm.biblionumber) WHERE SUBSTR(ExtractValue(bm.metadata,\'//controlfield[@tag="007"]\'),7,1) != "g" AND SUBSTR(ExtractValue(bm.metadata,\'//controlfield[@tag="007"]\'),1,2) = "sd" AND bi.itemtype = "CD"',
    'func' => \&fix_lastu_007_CD
                         });
$fixer->run();
