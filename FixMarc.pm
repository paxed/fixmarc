package FixMarc;

use utf8;
binmode STDOUT, ':utf8';

use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use MARC::Record;
use MARC::File::XML;
use MARC::Charset;
use DBI;

use Text::Diff;

use C4::Biblio;

# autoflush stdout/stderr
$| = 1;

MARC::Charset->assume_unicode(1);

# handle warnings coming from MARC::Charset &c
# we don't want to lose data to conversion error
my $warning_self;
my $warning_id;
my $warning_stop = 0;

my $old_warn_handler = $SIG{__WARN__};
$SIG{__WARN__} = sub {

    if (defined($warning_self)) {
	my $s = join(",", @_);
	$s =~ s/\n//g;
	$warning_self->error("WARN:" . $s);
	$warning_stop = 1;
    }
    undef $warning_self;
    undef $warning_id;

    $old_warn_handler->(@_) if $old_warn_handler;
};

sub _constructSelectSQL {
    my ($sql, $where, $limit) = @_;

    if (!defined($sql)) {
        $sql = "select biblionumber, metadata from biblio_metadata";
        $sql .= " where ".$where if (defined($where));
        $sql .= " order by biblionumber";
        $sql .= " limit ".$limit if (defined($limit) && $limit > 0);
    }
    return $sql;
}

sub _db_connect {
    my ($self) = @_;
    my $s = "DBI:" . $self->{'dbdata'}{'driver'} . ":dbname=" . $self->{'dbdata'}{'dbname'};

    if (defined($self->{'dbdata'}{'mysql_socket'})) {
        $s .= ";mysql_socket=" . $self->{'dbdata'}{'mysql_socket'};
    } else {
        $s .= ";host=" . $self->{'dbdata'}{'hostname'};
    }

    my $dbh = DBI->connect($s, $self->{'dbdata'}{'username'}, $self->{'dbdata'}{'password'}, {'RaiseError' => 1, mysql_enable_utf8 => 1});

    die("DB Error.") if (!$dbh);

    return $dbh;
}

sub _db_disconnect {
    my $dbh = shift || die("Error.");
    $dbh->disconnect();
}

sub _read_db_settings {
    my ($fname, $dbdata) = @_;
    my %data = %{$dbdata};

    if (-f "$fname" && -r "$fname") {
        my $fh;
        open ($fh, '<', $fname) or die("Could not read settings from $fname");
        while (my $line = <$fh>) {
            chomp($line);
            next if ($line =~ /^ *#/);
            if ($line =~ m/^(.+) *= *(.+)$/) {
                my ($key, $val) = ($1, $2);
                $data{$key} = $val if (exists($data{$key}));
            }
        }
        close($fh);
    }

    return \%data;
}

sub new {
    my ($class, $args) = @_;

    my %dbdata = (
        'hostname' => 'localhost',
        'username' => 'kohaadmin',
        'password' => 'katikoan',
        'dbname' => 'koha',
        'mysql_socket' => undef,
        'driver' => 'mysql'
        );

    %dbdata = %{_read_db_settings(".fixmarc.conf", \%dbdata)};

    my $help = 0;
    my $man = 0;

    my $sql = _constructSelectSQL($args->{'sql'}, $args->{'where'}, $args->{'limit'});

    if (!defined($args->{'updatesql'})) {
        $args->{'updatesql'} = 'update biblio_metadata set timestamp=NOW(), metadata=? where biblionumber=?';
    }

    my $self = bless {
        sql => $sql,
        updatesql => $args->{'updatesql'},
        where => $args->{'where'} || undef,
        limit => $args->{'limit'} || undef,
        verbose => $args->{'verbose'} || 0,
	debug => $args->{'debug'} || 0,
        dryrun => $args->{'dryrun'} || 0
    }, $class;

    $self->addfunc($args->{'func'}) if (defined($args->{'func'}));

    $self->{'dbdata'} = \%dbdata;

    my @tmpARGV = @ARGV;

    GetOptionsFromArray(\@tmpARGV,
        'db=s%' => sub { my $onam = $_[1]; my $oval = $_[2]; if (defined($self->{'dbdata'}{$onam})) { $self->{'dbdata'}{$onam} = $oval; } else { die("Unknown db setting."); } },
        'sql=s' => \$self->{'sql'},
        'where=s' => \$self->{'where'},
        'limit=s' => \$self->{'limit'},
        'v|verbose' => \$self->{'verbose'},
	'dry-run|dryrun' => \$self->{'dryrun'},
	'debug' => \$self->{'debug'},
        'help|h|?' => \$help,
        'man' => \$man,
        ) or pod2usage(2);

    pod2usage(1) if ($self->{'limit'} =~ /[^0-9]/);
    pod2usage(1) if ($help);
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    $self->{'sql'} = _constructSelectSQL(undef, $self->{'where'}, $self->{'limit'}) if ($args->{'where'} || $args->{'limit'});

    return $self;
}

sub addfunc {
    my ($self, $func) = @_;

    $self->{'func'} = [] if (!defined($self->{'func'}));
    push @{$self->{'func'}}, $func;
}

sub error {
    my ($self, $msg) = @_;

    print STDOUT "ERROR:$msg".(defined($self->{'id'}) ? " [id:".$self->{'id'}."]" : "")."\n";
}

sub msg {
    my ($self, $msg) = @_;

    print STDOUT "$msg".(defined($self->{'id'}) ? " [id:".$self->{'id'}."]" : "")."\n";
}

sub maybe_fix_marc {
    my ($self, $id, $marcxml) = @_;

    my $record;
    $warning_self = $self;
    $warning_id = $id;
    $warning_stop = 0;

    eval {
	$record = MARC::Record->new_from_xml($marcxml, 'utf-8');
    };
    if ($@) {
        $self->error("MARCXML record error");
	undef $warning_self;
	undef $warning_id;
	$warning_stop = 0;
        return;
    }

    my $origrecord = $record->clone();

    foreach my $tmpfunc (@{$self->{'func'}}) {
        &{$tmpfunc}($self, $record);
    }

    if (!$self->{'dryrun'} || $self->{'debug'}) {
        my $recxml = $record->as_xml_record();
        if ($origrecord->as_xml_record() ne $recxml) {
	    if ($self->{'debug'} && !$warning_stop) {
		$self->msg(diff(\$origrecord->as_xml_record(), \$recxml, { CONTEXT => 0 }));
	    }
	    if (!$self->{'dryrun'} && !$warning_stop) {
		my $sql = $self->{'updatesql'};
		my $sth = $self->{'dbh'}->prepare($sql);
		$sth->execute($recxml, $id);

		my $biblionumber = $id; # Hopefully ...
		C4::Biblio::ModZebra( $biblionumber, "specialUpdate", "biblioserver" );
	    }
        }
    }
    undef $warning_self;
    undef $warning_id;
    $warning_stop = 0;
}

sub run {
    my ($self) = @_;

    die("No SQL query") if (!defined($self->{'sql'}));
    die("No fixing function") if (!defined($self->{'func'}) || scalar(@{$self->{'func'}}) < 1);

    $self->msg("INFO:Dry run") if ($self->{'dryrun'});
    $self->msg("INFO:SQL:".$self->{'sql'});

    my $dbh = $self->{'dbh'} = $self->_db_connect();
    my $sth = $dbh->prepare($self->{'sql'});
    $sth->execute();

    my $i = 1;
    while (my $ref = $sth->fetchrow_hashref()) {
        my $id = $ref->{'biblionumber'};
        if ($id) {
            if ($self->{'verbose'}) {
                print STDERR "\n$i" if (!($i % 100));
                print STDERR ".";
            }
            my $marcxml = $ref->{'marc'} || $ref->{'marcxml'} || $ref->{'metadata'} || '';
            $self->{'id'} = $id;
            $self->maybe_fix_marc($id, $marcxml) if ($marcxml ne '');
            $i++;
        }
    }

    _db_disconnect($dbh);
    undef $self->{'dbh'};
}

1;

__END__

=head1 NAME

FixMarc.pm

=head1 DESCRIPTION

Library for making it easier to mangle MARCXML records

=cut
