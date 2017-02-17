#!/usr/bin/perl
#
use 5.022 ;

use File::Copy ;
use DBI ;
use Image::Magick ;

no warnings 'experimental::smartmatch' ;

    my $dbh ;
    my ( %sty, $szid, %stysz, $sty, $id, @rec ) ;

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
  for ( @{ $dbh-> selectall_arrayref("SELECT style_id, name, folder, sizing FROM style", { Slice => {} }) } )
  {
	my $sty= $_->{folder} || lc $_->{name} ;
	$sty{$sty}= $_->{style_id} ;
	$stysz{$sty}= $_->{sizing} ;
  }
}

sub setupid
{
  my ($imna)= $dbh-> selectrow_array("SELECT max(name) FROM media") ;
  ($id)= $imna =~ /(\d+)/ ;

  die "no images found" unless $id ;
  $id += 2 ;
}

sub setupsz
{
  my ($sztx)= @_ ;
  my $szing= $stysz{$sty} ;

  my ($sizes_id)= $dbh->selectrow_array( "SELECT sizes_id FROM sizes JOIN sizing AS rng USING (sizes_id) "
  					 . "WHERE code = ? AND rng.name = ?",
					 undef,
					 uc $sztx, $szing
				       ) ;

  # say "$sztx to $szing = $sizes_id" ;
  die "Unable to find $sztx in $sty ( $szing ) " unless $sizes_id ;
  $szid= $sizes_id ;
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
  @lst= <DSC_[0-9]*.JPG> unless @lst ;
  @lst= <IMG_[0-9]*.JPG> unless @lst ;
  return @lst 
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
  if ( $x > $y )
  {
    $img-> Rotate( degrees=> 90.0 ) ;
    ($x, $y) = $img->Get('columns', 'height') ;
  }

  my ($newx, $newy) ;
  if ( $x > $y ) { $newx= 1920 ;  $newy= int( 0.5 + $newx * $y / $x ) ; }
	else { $newy= 1920 ;  $newx= int( 0.5 + $newy * $x / $y ) ; }

  $img-> Resize( geometry => "${newx}x${newy}" ) ;
  $img-> Flatten() ;
  ($x, $y)= $img->Get( 'columns', 'height') ;

  my $imgf= sprintf("i%05d", $id ++ ) ;
  $img-> Write( "../../page/img/$imgf.jpg" ) ;

  my $tag ;
  $tag= 'GEN' unless $szid ;
  push @rec, [ $imgf, "img/$imgf.jpg", "${x}x$y", 1, $sty{$sty}, 100, 'N', 'Y', $tag ] ;

  print "." ;
}

{
  setupdb() ;
  setupstyle() ;
  setupid() ;
  $|= 1 ;

  my ( $sztx, $tags ) ;
  my @lst= scanfiles() ;
  ($sty, $sztx, $tags)= @ARGV ;

  die "unknown style $sty" unless $sty ~~ %sty ;
  setupsz($sztx) if $sztx ;

  for my $im ( @lst )
  {
  	process( $im ) ;
  }

  die "no processed images" unless @rec ;
  print " " ;

  my $sth= $dbh->prepare( "INSERT INTO media (name, `path`, geom, mediatype, style_id, owner_id, ispublic, isactive, tags) " 
						. "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
		   ) ;

  my ( $recx, @postrec ) ;

  for ( @rec )
  {
  	$sth-> execute( @$_ ) ;
	print "," ;
	$recx= $dbh-> last_insert_id( "", "", "media", "media_id" ) ;
	push @postrec, $recx if $szid ;
  }
  say "" ;

  $tags //= '' ;
  if ( @postrec )
  {
    $sth= $dbh->prepare( "INSERT INTO item (media_id, sizes_id, style_fk, owner_fk, `count`, tags) "
    			 . "VALUES (?, ?, ?, 100, 1, ?)"
		       ) ;

    for ( @postrec ) { $sth-> execute( $_, $szid, $sty{$sty}, $tags ) }
  }

  for ( @lst )
  {
	rename( $_, "done/$_" ) ;
  }

  say "done." ;
}
