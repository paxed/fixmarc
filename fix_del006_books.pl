use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;


sub fix_del006_books {
    my ($fixer, $record) = @_;

    my @flist = $record->field('006');
    my $cnt = scalar(@flist);
    if ($cnt > 0) {
        my @vals;

        foreach my $f (@flist) {
            push(@vals, $f->data());
        }

        $record->delete_fields(@flist);
        $fixer->msg("Deleted ".$cnt." x 006 fields ('".join("','", @vals)."')");
    }
}

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//controlfield[@tag="006"])\') > 0 and substr(ExtractValue(metadata, \'//leader\'),7,1) = "a"',
    'func' => \&fix_del006_books
                         });
$fixer->run();
