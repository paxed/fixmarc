use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Replace eg. 600.ind2 with either 4 or 7, depending if the $2 subfield exists.

my @thes_fields = ('600', '610', '611', '630', '647', '648', '650', '651', '655'); # indicator 2 of each


sub fix_thesaurus_source {
    my ($fixer, $record) = @_;

    my @flist = $record->field('6..'); # @thes_fields all start with '6'
    foreach my $f (@flist) {

        next if (!(grep $f->tag() eq $_, @thes_fields));

        my $ind = $f->indicator(2) . "";
        my $has2 = 0;
        my $newind = "";

        my @sfa = $f->subfields();
        foreach my $sf (@sfa) {
            if ($sf->[0] eq '2') {
                $has2 = 1;
                last;
            }
        }
        if ($ind !~ /^[0-7]$/) {
            $newind = $has2 ? "7" : "4";
            $f->set_indicator(2, $newind);
            $fixer->msg("Changed ".$f->tag().".ind2:'".$ind."'=>'".$newind."'");
        }
    }
}

my $queryfieldstr = '@tag="'.join('" or @tag="', @thes_fields).'"';

my $fixer = FixMarc->new({
    'where' => 'ExtractValue(metadata, \'count(//datafield['.$queryfieldstr.'])\') > 0',
    'func' => \&fix_thesaurus_source
                         });
$fixer->run();
