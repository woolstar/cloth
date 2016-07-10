
use 5.022 ;
use DBI ;

use vars qw($dbh) ;

require Exporter;
our @ISA = ("Exporter") ;
our @EXPORT = qw($dbh) ;

sub gen::db::import
{
  my $package = shift;
  my %param = @_;

  my $path= "../db/" ;

  my $db= $param{db} ;

  $dbh= DBI-> connect("dbi:SQLite:dbname=$path$db", "", "" ) ;
  # $dbh= DBI-> connect("dbi:SQLite:dbname=$path$db", "", "", {PrintError => 0, RaiseError => 0} ) ;
  $dbh-> {RaiseError}= 1 if $dbh ;
}

1 ;
