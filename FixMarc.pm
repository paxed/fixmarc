package FixMarc;

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use MARC::Record;
use MARC::File::XML (BinaryEncoding => 'UTF-8');
use MARC::Charset;
use DBI;

# autoflush stdout/stderr
$| = 1;

MARC::Charset->assume_unicode(1);

sub _constructSelectSQL {
    my ($sql, $where) = @_;

    if (!defined($sql)) {
        $sql = "select biblionumber, metadata from biblio_metadata";
        $sql .= " where ".$where if (defined($where));
        $sql .= " order by biblionumber";
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

    my $help = 0;
    my $man = 0;

    my $sql = _constructSelectSQL($args->{'sql'}, $args->{'where'});

    if (!defined($args->{'updatesql'})) {
        $args->{'updatesql'} = 'update biblio_metadata set timestamp=NOW(), metadata=? where biblionumber=?';
    }

    my $self = bless {
        sql => $sql,
        updatesql => $args->{'updatesql'},
        verbose => $args->{'verbose'} || 0,
        dryrun => $args->{'dryrun'} || 0
    }, $class;

    $self->addfunc($args->{'func'}) if (defined($args->{'func'}));

    $self->{'dbdata'} = \%dbdata;

    GetOptions(
        'db=s%' => sub { my $onam = $_[1]; my $oval = $_[2]; if (defined($self->{'dbdata'}{$onam})) { $self->{'dbdata'}{$onam} = $oval; } else { die("Unknown db setting."); } },
        'sql=s' => \$self->{'sql'},
        'where=s' => sub { $self->{'sql'} = _constructSelectSQL(undef, $_[2]); },
        'v|verbose' => \$self->{'verbose'},
        'dry-run|dryrun' => \$self->{'dryrun'},
        'help|h|?' => \$help,
        'man' => \$man,
        ) or pod2usage(2);

    pod2usage(1) if ($help);
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    return $self;
}

sub addfunc {
    my ($self, $func) = @_;

    $self->{'func'} = [] if (!defined($self->{'func'}));
    push @{$self->{'func'}}, $func;
}

sub error {
    my ($self, $msg) = @_;

    print STDOUT "ERROR:$msg [id:".$self->{'id'}."]\n";
}

sub msg {
    my ($self, $msg) = @_;

    print STDOUT "$msg [id:".$self->{'id'}."]\n";
}


#
# TODO:
#
# my $newfield = MARC::Field->new('007', $data);
# $record->insert_fields_ordered($newfield);
#
# @flist = $record->field('007');
# my $text = $flist[0]->data();
# $flist[0]->update($text);
#
# $flist[0]->tag()
#
# my @sflist = $flist[0]->subfields();
#
# $flist[0]->indicator(1);
# $flist[0]->indicator(2);
#
# $flist[0]->set_indicator(1, '3');
#
# my $fld = MARC::Field->new('041', $f->indicator(1), $f->indicator(2), '9' => '');
#
# $fld->add_subfields();
#
# $record->delete_fields(@flist);
#
# $fld->delete_subfield(code => '9');
#
# $fld->subfield('c');
#
# 
#
#

sub maybe_fix_marc {
    my ($self, $id, $marcxml) = @_;

    my $record;

    eval {
	$record = MARC::Record->new_from_xml($marcxml);
    };
    if ($@) {
        $self->error("MARCXML record error");
        return;
    }

    my $origrecord = $record->clone();

    foreach my $tmpfunc (@{$self->{'func'}}) {
        &{$tmpfunc}($self, $record);
    }

    if (!$self->{'dryrun'}) {
        my $recxml = $record->as_xml_record();
        if ($origrecord->as_xml_record() ne $recxml) {
            my $sql = $self->{'updatesql'};
            my $sth = $self->{'dbh'}->prepare($sql);
            $sth->execute($recxml, $id);
        }
    }
}

sub run {
    my ($self) = @_;

    die("No SQL query") if (!defined($self->{'sql'}));
    die("No fixing function") if (!defined($self->{'func'}) || scalar(@{$self->{'func'}}) < 1);

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
