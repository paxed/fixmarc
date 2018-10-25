use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;

# Reorder the MARC Record fields to numerical order
sub marc_reorder {
    my ($fixer, $record) = @_;
    @{$record->{_fields}} = sort { $a->tag() cmp $b->tag() } @{$record->{_fields}};
}


my $fixer = FixMarc->new({
    'func' => \&marc_reorder
                         });
$fixer->run();
