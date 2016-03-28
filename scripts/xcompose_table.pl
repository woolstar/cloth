 use 5.020 ;
 use Image::Magick ;

 no warnings "experimental::smartmatch" ;

 my ( %isize, %imark ) ;

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

{
  load_size() ;
  load_mark() ;
  say "setup. " ;

  for ( <*.jpg> )
  {
    my $img= new Image::Magick ;
    $img-> Read( $_ ) ;
    $img-> Transpose() ;
    $img-> Flop() ;
    my ($x,$y,$bytes)= $img-> Get('columns', 'height', 'filesize') ;
    my ($qt,$sz)= /\w+_\d+_(\d+)_(\w+)\./ ;
    say "$_ :: $bytes - n=$qt, sz=$sz" ;
    say "no template for $sz" unless $sz ~~ %isize ;
    next unless $sz ~~ %isize ;

    my $destx= int(960 * $x / $y ) ;
    my $desty= 960 ;

    $img-> Normalize() ;
    $img-> Resize( geometry => "${x}x960" ) ;

    ## size
    # $img-> Composite( image => $isize{$sz}, gravity => 'North' ) ;

    ## watermark
    $img-> Composite( Image => $imark{3},
		      gravity => 'SouthEast',
		      geometry => '+16+16'
		    ) ;

    $img-> Flatten() ;
    $img-> Write( "done/$_" ) ;
  }

  say "Done." ;
  sleep 2 ;
}
