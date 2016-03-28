 use 5.020 ;

 use File::Copy 'cp' ;
 use Image::Magick ;

 no warnings "experimental::smartmatch" ;

 my ( %isize, %icover, %imark ) ;

my %szrank = ( XXS => 10, 
	       XS => 11,
	       S => 12,
	       M => 13,
	       L => 14,
	       XL => 15,
	       '2XL' => 16,
	       '3XL' => 17,
	       'KS' => 25,
	       'KL' => 26,
	       'TW' => 30,
	       'OS' => 31,
	       'TC' => 32
	      ) ;

my $rec= 2000 ;

sub load_size
{
  for ( <util/u_size_*.jpg> )
  {
    my ($sz)= /u_size_(\w+)\./ ;
    next unless $sz ;
    my $img= new Image::Magick ;
    $img-> Read($_) ;
    $isize{$sz}= $img ;
  }
}

sub load_cover
{
  for ( <util/cover_*.jpg> )
  {
    my ($typ)= /cover_(\w+)\./ ;
    next unless $typ ;
    $icover{$typ}= $_ ;
  }
}

sub load_mark
{
  for ( 3, 6 )
  {
    my $fi= "util/cw_jeanne_${_}x${_}.tif" ;
    say "FAIL: unable open $fi" && next unless -e $fi ;
    my $img= new Image::Magick ;
    $img-> Read($fi) ;
    $imark{$_}= $img ;
  }
}

sub chksz
{
  my ($sz)= @_ ;
  return if $sz ~~ %szrank && $sz ~~ %isize ;

  die "Size error $sz" ;
}

sub process
{
  my ($fi, $typ, $sz, $ct)= @_ ;
  return unless $ct ;
  
  my $szrank= $szrank{$sz} ;
  my $szdir= "sz$szrank{$sz}_${sz}_$typ" ;

  my $path= 'prep/' ;  mkdir $path unless -d $path ;
  $path .= $typ . '/' ;
  if ( ! -d $path ) {
    mkdir $path ;
    cp( $icover{$typ}, "$path/0cover.jpg" ) if $typ ~~ %icover ;
  }
  $path .= $szdir . '/' ;  mkdir $path unless -d $path ;
  
  my $img= new Image::Magick ;
  $img-> Read( "db/${fi}.jpg" ) ;

  my ($x,$y,$bytes)= $img-> Get('columns', 'height', 'filesize') ;
  # say "$x $y :: $bytes $typ $sz" ;

  my ($destx, $desty) ;
  $desty= 960 ;
  $destx= int($desty * $x / $y ) ;

  $img-> Resize( geometry => "${destx}x${desty}" ) ;

  ## size
  $img-> Composite( image => $isize{$sz},
		    gravity => 'NorthEast',
		    geometry => '-8-8'
		  ) ;

  ## watermark
  $img-> Composite( Image => $imark{3},
		    gravity => 'SouthEast',
		    geometry => '+16+16'
		  ) ;

  $img-> Flatten() ;

  $ct= 1 ;
 # $ct= 1 if $typ eq 'monroe' ;
  for ( 1..$ct )
  {
    my $irec= sprintf("%05d", $rec ++ ) ;
    $img-> Write( $path . "${typ}_${szrank}sz${sz}_${irec}.jpg" ) ;
  }
}


{
  load_size() ;
  load_cover() ;
  load_mark() ;
  say "setup. " ;

  my $otyp ;
  open my $LIST, '<', 'db.txt' || die "no db.txt" ;

  for ( <$LIST> )
  {
    my ($typ, $img, $szs)= /(\w+)\s+(i\d+)\s+\(([\w\d\s]++)\)/ ;
    if ( $typ && ( $typ ne $otyp )) {
      say "Found $typ $szs" ;
      $otyp= $typ ;
    }

    for ( $szs =~ /(\d+\s+\w+)/g )
    {
      my ($n, $sz)= /(\d+)\s+(\w+)/ ;
      chksz( $sz) ;
      process($img, $typ, $sz, $n) ;
    }
  }

  say "Done." ;
  sleep 2 ;
}
