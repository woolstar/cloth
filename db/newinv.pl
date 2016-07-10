#!/usr/bin/perl

  use 5.022 ;

  use File::Copy ;
  use DBI ;
  use Graphics::Magick ;

  no warnings 'experimental::smartmatch' ;

    my $dbh ;
    my ( %sty, @rec, %exist ) ;

sub load_file
{
  my ($filename, $data) = @_;
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
  my $db= '/cygdrive/u/a/dev/web/db/prod.s3db' ;
  $dbh = DBI->connect("dbi:SQLite:dbname=$db","","") || die "no db" ;
}

sub setupstyle
{
  for ( @{ $dbh-> selectall_arrayref("SELECT style_id, name, folder FROM style", { Slice => {} }) } )
  {
    my $sty= $_->{folder} || lc $_->{name} ;
    $sty{$sty}= $_->{style_id} ;
  }
}

sub setupexist
{
  @exist{ @{ $dbh-> selectcol_arrayref("SELECT name FROM media WHERE ownerid = 100") } } = undef ;
}

sub loadgeom
{
  my $i= new Graphics::Magick ;
  $i-> Read( @_ ) ;

  my ($x, $y)= $i-> Get('columns', 'height') ;
  die "no image @_" unless $x && $y ;

  return "${x}x$y" ;
}

sub scanimg
{
  my ($i, $sty)= @_ ;
  for ( $i )
  {
    my $fi= "db/$_.jpg" ;
    my ($id)= /(\w+)/ ;

    my $sz= -s $fi ;
    die "unable to open $fi" unless $sz ;

    my $geom= loadgeom( $fi ) ;
    push @rec, [ $_, "img/$_.jpg", $geom, 1, $sty{$sty}, 100, 'N', 'Y', 'GEN' ] ;
    print '.' ;
  }
}

{
  setupdb() ;
  setupstyle() ;
  $|= 1 ;

  chdir( "/cygdrive/p/img" ) ;
  my $txt= load_file('db.txt') ;

  my ($osty ) ;

  for ( $txt =~ /(\w++\s+\w++\s+\(\d\s\w+\))/g )
  {
    my ($sty, $img, $ct, $sz)= /(\w++)\s+(\w++)\s+\((\d++)\s(\w++)\)/ ;
    next unless $ct ;
    die "not GEN $sz" unless $sz eq 'GEN' ;
    die "not style $sty" unless $sty ~~ %sty ;

    print "\n$sty " if $sty ne $osty ;
    scanimg( $img, $sty ) ;
    $osty= $sty ;
  }

  die "nothing." unless @rec ;
  say " prep." ;

  my $sth= $dbh->prepare( "INSERT INTO media (name, `path`, geom, mediatype, style_id, owner_id, ispublic, isactive, tags) "
  			  . "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
			) ;

  my $dest= "/cygdrive/u/a/dev/web/page/" ;

  for ( @rec )
  {
    my ($id, $pth)= @$_ ;
    next if $id ~~ %exist ;

    copy("db/$id.jpg", $dest . $pth . '.jpg' ) ;
    $sth-> execute( @$_ ) ;
    say $id ;
  }

}

