#!/usr/bin/perl
#
use 5.022 ;

use File::Copy ;
use DBI ;
use Image::Magick ;

no warnings 'experimental::smartmatch' ;

    my $dbh ;
	my ( %sty, $sty, $id, @rec ) ;

sub load_file
{
	my ($filename, $data) = @_;
	local($/, *IN);
	if (open(IN, $filename))
	{
	  $data= <IN> ;
	  close IN
	} 
	$data
}

sub setupdb
{
  my $db=  '/cygdrive/u/a/dev/web/db/prod.s3db' ;
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

sub setupid
{
  my ($imna)= $dbh-> selectrow_array("SELECT max(name) FROM media") ;
  ($id)= $imna =~ /(\d+)/ ;

  die "no images found" unless $id ;
  $id += 2 ;
}

sub loadgeom
{
  my $i= new Graphics::Magick ;
  $i-> Read( @_ ) ;
  my ($x, $y)= $i-> Get('columns', 'height') ;
  die "no image @_" unless $x && $y ;

  return "${x}x$y" ;
}


sub scanfiles
{
  my @lst ;

  @lst= <_DSC[0-9]*.JPG> ;
}

sub process
{
  my ($imf)= @_ ;

  my $img= new Image::Magick ;
  $img-> Read( $imf ) ;

  $img-> AutoOrient() ;
  $img-> Set('%[EXIF:UserComment]', "Jeanne Lularoe $sty - $id") ;
  $img-> Set('%[EXIF:Copyright]', "(c) 2016 Jeanne Woolverton") ;
  $img-> Set('%[EXIF:orientation]', 0) ;

  my ($x, $y) = $img->Get('columns', 'height') ;
  my ($newx, $newy) ;
  if ( $x > $y ) { $newx= 1920 ;  $newy= int( 0.5 + $newx * $y / $x ) ; }
	else { $newy= 1920 ;  $newx= int( 0.5 + $newy * $x / $y ) ; }

  $img-> Resize( geometry => "${newx}x${newy}" ) ;
  $img-> Flatten() ;
  ($x, $y)= $img->Get( 'columns', 'height') ;

  my $imgf= sprintf("i%05d", $id ++ ) ;
  $img-> Write( "../../page/img/$imgf.jpg" ) ;
  push @rec, [ $imgf, "img/$imgf.jpg", "${x}x$y", 1, $sty{$sty}, 100, 'N', 'Y', 'GEN' ] ;

  print "." ;
}

{
  setupdb() ;
  setupstyle() ;
  setupid() ;
  $|= 1 ;

  my @lst= scanfiles() ;
  ($sty)= @ARGV ;

  die "unknown style $sty" unless $sty ~~ %sty ;

  for my $im ( @lst )
  {
  	process( $im ) ;
  }

  die "no processed images" unless @rec ;
  print " " ;

  my $sth= $dbh->prepare( "INSERT INTO media (name, `path`, geom, mediatype, style_id, owner_id, ispublic, isactive, tags) " 
						. "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
		   ) ;

  for ( @rec )
  {
  	$sth-> execute( @$_ ) ;
	print "," ;
  }
  say "" ;

  for ( @lst )
  {
	rename( $_, 'done/$_' ) ;
  }

  say "done." ;
}
