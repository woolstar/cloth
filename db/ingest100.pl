#!/usr/bin/perl

  use 5.016 ;

  use Data::Dumper ;
  use File::Copy ;

  use DBI ;
  use Graphics::Magick ;

  no warnings 'experimental::smartmatch' ;

  my $dbh ;
  my ( %sty, %list, %exist ) ;

sub load_file
{
  my($filename, $data) = @_;
  local($/, *IN);
  if (open(IN, $filename))
  {
    $data = <IN>;
    close IN;
  }
  $data;
}


sub setupdb
{
  $dbh = DBI->connect("dbi:SQLite:dbname=test1.sldb","","") || die "no db" ;
}

sub setupstyle
{
  for ( @{ $dbh-> selectall_arrayref("SELECT id, name, folder FROM style", { Slice => {} }) } )
  {
    my $sty= $_->{folder} || lc $_->{name} ;
    $sty{$sty}= $_->{id} ;
  }
}

sub setupexist
{
  @exist{ @{ $dbh-> selectcol_arrayref("SELECT name FROM media WHERE ownerid = 100") } } = undef ;
}

sub setuplist
{
  my $lst= load_file('list') ;
  for ( $lst =~ /(\w+,\s+\w+\.jpg)/g )
  {
    my ($sty, $im) = /(\w+),\s+(\w+)/ ;
    $list{$im}= $sty ;

    die "No $sty" unless $sty ~~ %sty ;
  }
}

sub loadgeom
{
  my $i= new Graphics::Magick ;
  $i-> Read( @_ ) ;

  my ($x, $y)= $i-> Get('columns', 'height') ;
  die "no image @_" unless $x && $y ;

  return "${x}x$y" ;
}

{
  setupdb() ;
  setupstyle() ;

  chdir( "/cygdrive/u/a/dev/web/tmp" ) ;
  setuplist() ;

  my @rec ;

  while ( <i*.jpg> )
  {
    my $sz= -s $_ ;
    my ($id)= /(\w+)/ ;
    my $geom= loadgeom( $_ ) ;
    push @rec, [ $id, "page/img/$_", $geom, 1, $sty{$list{$id}}, 100, 'N', 'Y', '' ] ;
  }

  exit unless @rec ;
  say STDERR "ingest" ;

  my $sth= $dbh-> prepare( "INSERT INTO media (name, `path`, geom, mediatype, styleid, ownerid, ispublic, isactive, tags) "
			   . "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
  			 ) ;

  for ( @rec )
  {
    my ($id, $pth)= @$_ ;
    next if $id ~~ %exist ;

    copy("$id.jpg", "../" . $pth) ;
    $sth-> execute( @$_ ) ;
    say $id ;
  }
}
