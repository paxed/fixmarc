use strict;
use warnings;

do './FixMarc.pm';
use MARC::Record;
use MARC::Field;
use XML::Simple;

use open ':std', ':encoding(UTF-8)';

my $LANGUAGESXML='/tmp/languages.xml';

my %lang;

system("wget http://www.loc.gov/standards/codelists/languages.xml -O \"$LANGUAGESXML\"") if (! -f $LANGUAGESXML);

my $ref = XMLin($LANGUAGESXML);
my $languages = $ref->{'languages'}->{'language'};

foreach my $l (@{$languages}) {
    my $code = $l->{'code'};
    my $name = (ref($l->{'name'}) eq 'HASH' ? $l->{'name'}{'content'} : $l->{'name'});
    next if (ref($code) eq 'HASH' && $code->{'status'} eq 'obsolete');

    $lang{$code} = $name;
}
$lang{'|||'} = 'Not coded';


sub str_replace_nth {
    my ($str, $nth, $chr) = @_;

    return substr($str, 0, $nth).$chr.substr($str,($nth + length($chr))-length($str));
}

sub chk_languages {
    my ($fixer, $record) = @_;

    my $f008 = $record->field('008');
    if (defined($f008)) {
        my $f008data = $f008->data();

        if (length($f008data) == 40) {
            my $l = substr($f008data, 35, 3) || '';
            $fixer->error("Unknown lang '".$l."' in 008") if (!defined($lang{$l}) && $l ne '   ');
        }
    }

    my @flds = $record->field('041');
    foreach my $f (@flds) {
        my @sfa = $f->subfields();
        foreach my $sf (@sfa) {
            next if ($sf->[0] !~ /[a-z]/);
            my $l = $sf->[1] || '';
            $fixer->error("Unknown lang '".$l."' in 041".$sf->[0]) if (($l eq '|||') || !defined($lang{$l}));
        }
    }
}

my $fixer = FixMarc->new({ 'func' => \&chk_languages });
$fixer->run();
