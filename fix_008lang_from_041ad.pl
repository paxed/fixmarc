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

sub fix_languages {
    my ($fixer, $record) = @_;

    my $f008 = $record->field('008');
    if (defined($f008)) {
        my $f008data = $f008->data();

        if (length($f008data) == 40) {
            my $l = substr($f008data, 35, 3);
            if (defined($l) && $l eq '|||') {
                my $nl = $record->subfield('041', 'a') || $record->subfield('041', 'd') || '';
                if (defined($lang{lc($nl)})) {
                    my $tmp = str_replace_nth($f008data, 35, lc($nl));
                    $f008->update($tmp);
                    $fixer->msg("Updated 008:'".$f008data."'=>'".$tmp."'");
                } elsif ($nl ne '') {
                    $fixer->error("Unknown lang '".$nl."' in 041");
                }
            }
        }
    }
}

my $fixer = FixMarc->new({ 'func' => \&fix_languages });
$fixer->run();
