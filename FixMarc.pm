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
use XML::LibXML;

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
        $sql = "select biblionumber, metadata, timestamp from biblio_metadata";
        $sql .= " where ".$where if (defined($where));
        $sql .= " order by biblionumber";
    }

    if ($sql !~ / limit /i && defined($limit) && ($limit > 0)) {
        $sql .= " limit ".$limit;
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

sub _read_db_settings_xml {
    my ($fname, $dbdata) = @_;
    my %data = %{$dbdata};

    my %matchxml = (
        '//config/db_scheme' => 'driver',
        '//config/database' => 'dbname',
        '//config/hostname' => 'hostname',
        '//config/user' => 'username',
        '//config/pass' => 'password',
        # TODO: port, socket
        );

    my $dom = XML::LibXML->load_xml(location => $fname);

    foreach my $k (keys(%matchxml)) {
        my $v = $matchxml{$k};
        $data{$v} = $dom->findvalue($k) || $data{$v};
    }

    return \%data;
}

sub _read_db_settings {
    my ($fname, $dbdata) = @_;
    my %data = %{$dbdata};

    return _read_db_settings_xml($fname, $dbdata) if ($fname =~ /\.xml$/);

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

    # config files, in order of preference
    my @configfiles = (
        "/etc/koha/koha-conf.xml",
        ".fixmarc.conf"
        );

    my $help = 0;
    my $man = 0;
    my $used_configfile = 0;

    my $sql = _constructSelectSQL($args->{'sql'}, $args->{'where'}, $args->{'limit'});

    if (!defined($args->{'updatesql'})) {
        $args->{'updatesql'} = 'update biblio_metadata set timestamp=NOW(), metadata=? where biblionumber=?';
    }

    my $self = bless {
        sql => $sql,
        updatesql => $args->{'updatesql'},
        where => $args->{'where'} || undef,
        limit => $args->{'limit'} || undef,
        zebra => $args->{'zebra'} || 0,
        verbose => $args->{'verbose'} || 0,
	debug => $args->{'debug'} || 0,
        diff_context => $args->{'diff_context'} || 0,
        uniqlog => $args->{'uniqlog'} || 0,
        dryrun => $args->{'dryrun'} || 0
    }, $class;

    $self->{'uniq_logs'} = undef;

    $self->addfunc($args->{'func'}) if (defined($args->{'func'}));

    my @tmpARGV = @ARGV;

    GetOptionsFromArray(\@tmpARGV,
        'db=s%' => sub { my $onam = $_[1]; my $oval = $_[2]; if (defined($self->{'dbdata'}{$onam})) { $self->{'dbdata'}{$onam} = $oval; } else { die("Unknown db setting."); } },
        'sql=s' => \$self->{'sql'},
        'where=s' => \$self->{'where'},
        'limit=s' => \$self->{'limit'},
        'zebra' => \$self->{'zebra'},
        'v|verbose' => \$self->{'verbose'},
	'dry-run|dryrun' => \$self->{'dryrun'},
        'debug' => \$self->{'debug'},
        'diff-context|diff_context=i' => \$self->{'diff_context'},
        'uniqlog' => \$self->{'uniqlog'},
        'help|h|?' => \$help,
        'man' => \$man,
        'configfile=s' => sub { my $fn = $_[1]; if (-f $fn && -r $fn) { %dbdata = %{_read_db_settings($fn, \%dbdata)}; $self->{'dbdata'} = \%dbdata; }; $used_configfile = 1; },
        ) or pod2usage(2);

    pod2usage(1) if ($self->{'limit'} =~ /[^0-9]/);
    pod2usage(1) if ($help);
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if (!$used_configfile) {
        foreach my $fname (@configfiles) {
            if (-f $fname && -r $fname) {
                %dbdata = %{_read_db_settings($fname, \%dbdata)};
                last;
            }
        }
        $self->{'dbdata'} = \%dbdata;
    }

    $self->{'debug'} = 1 if ($self->{'uniqlog'});

    $self->{'sql'} = _constructSelectSQL($args->{'sql'}, $self->{'where'}, $self->{'limit'}) if ($self->{'where'} || $self->{'limit'});

    $self->msg("INFO: Using db: " . $self->{'dbdata'}{'dbname'});
    $self->msg("INFO: PARAMS: " . join(" ", @ARGV));

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

sub gather_uniq_changes {
    my ($self, $data) = @_;

    my $indata = 0;
    my $currdata = "";
    my $haschange = 0;

    foreach my $line (split(/[\r\n]/, $data)) {
        $line =~ s/[\r\n]+$//;

        $indata = 1 if ($line =~ m/^\s*(<leader>|<controlfield|<datafield)/);

        if ($indata) {
            $currdata .= "\n" if ($currdata ne "");
            $currdata .= $line;
            $haschange = 1 if ($line =~ m/^[-+]/);
        }

        $indata = 0 if ($line =~ m/(<\/leader>|<\/controlfield>|<\/datafield>)\s*$/);

        if (!$indata && ($currdata ne "")) {
            if ($haschange) {
                $self->{'uniq_logs'}{$currdata} = 0 if (!defined($self->{'uniq_logs'}{$currdata}));
                $self->{'uniq_logs'}{$currdata}++;
            }
            $currdata = "";
            $haschange = 0;
        }
    }
}

sub print_uniq_changes {
    my ($self) = @_;

    return if (!$self->{'uniqlog'} || !defined($self->{'uniq_logs'}));

    my @keys = sort { $self->{'uniq_logs'}{$b} <=> $self->{'uniq_logs'}{$a} } keys(%{$self->{'uniq_logs'}});

    foreach my $k (@keys) {
        $self->msg("------------ COUNT:".$self->{'uniq_logs'}{$k}."\n".$k."");
    }
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
                if ($self->{'uniqlog'}) {
                    my $diffi = diff(\$origrecord->as_xml_record(), \$recxml, { CONTEXT => 100 });
                    $self->gather_uniq_changes($diffi);
                } else {
                    $self->msg(diff(\$origrecord->as_xml_record(), \$recxml, { CONTEXT => $self->{'diff_context'} }));
                }
	    }
	    if (!$self->{'dryrun'} && !$warning_stop) {
		my $sql = $self->{'updatesql'};
		my $sth = $self->{'dbh'}->prepare($sql);
		$sth->execute($recxml, $id);

                if ($self->{'zebra'}) {
                    my $biblionumber = $id; # Hopefully ...
                    C4::Biblio::ModZebra( $biblionumber, "specialUpdate", "biblioserver" );
                }
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
            $self->{'timestamp'} = $ref->{'timestamp'} || undef;
            $self->maybe_fix_marc($id, $marcxml) if ($marcxml ne '');
            $i++;
        }
    }

    _db_disconnect($dbh);
    undef $self->{'dbh'};

    undef $self->{'id'};
    $self->print_uniq_changes();
}

1;

__END__

=head1 NAME

FixMarc.pm

=head1 DESCRIPTION

Library for making it easier to mangle MARCXML records

=cut
