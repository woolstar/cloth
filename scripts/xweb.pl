 use 5.020 ;
 use Image::Magick ;

 no warnings "experimental::smartmatch" ;

 my ( %isize, %imark ) ;

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

my %pages ;

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

sub chksz
{
  my ($sz)= @_ ;
  return if $sz ~~ %szrank && $sz ~~ %isize ;

  die "Size error $sz" ;
}

sub process
{
  my ($fi, $typ)= @_ ;

  my $path= 'html/' ;  mkdir $path unless -d $path ;
  $path .= 'im' . '/' ;  mkdir $path unless -d $path ;

  my $img= new Image::Magick ;
  $img-> Read( "db/${fi}.jpg" ) ;

  my ($x,$y,$bytes)= $img-> Get('columns', 'height', 'filesize') ;
  # say "$x $y :: $bytes $typ" ;
  if ( ! $y )
  {
    say "Unable to open $fi" ;
    return 0 ;
  }

  my ($destx, $desty) ;
  $desty= 200 ;
  $destx= int($desty * $x / $y ) ;

  $img-> Resize( geometry => "${destx}x${desty}" ) ;

  $img-> Flatten() ;

  my $n= $rec ++ ;
  my $irec= sprintf("%05d", $n ) ;
  $img-> Write( $path . "i${irec}.jpg" ) ;
  return $n ;
}

sub print_pages
{
	my $mtxt ;

	$mtxt= "<html>\n<body>\n" ;

	for my $ty ( sort keys %pages )
	{
		my %szs ;
		my $txt ;

		$txt= "<html>\n<body>\n$ty\n<p>" ;

		for my $sz ( sort { $szrank{$a} <=> $szrank{$b} } keys %{$pages{$ty}} )
		{
			my $ct ;
			my $lst_= $pages{$ty}{$sz} ;

			$txt .= "Size $sz<hr>\n" ;

			my ($ta, $tb) ;

			for ( @$lst_ )
			{
				my ($ik, $imna, $n)= @$_ ;
				$ct += $n ;

				$ta .= "<td><img src=\"im/i0$ik.jpg\"></td>\n" ;
				$tb .= "<td>i $imna<br>Count $n</td>\n" ;
			}

			$szs{$sz}= $ct ;
			$txt .= "<table border=0>\n" ;
			$txt .= "<tr>$ta</tr>\n" ;
			$txt .= "<tr>$tb</tr>\n" ;
			$txt .= "</table>\n<p>\n" ;
		}

		$txt .= "</body></html>\n" ;

		{
		  open my $FHTML, '>', "html/page_$ty.html" ;
		  print $FHTML $txt ;
		}

		$mtxt .= "<a href='page_$ty.html'>$ty</a><br>" ;
		for my $sz ( sort { $szrank{$a} <=> $szrank{$b} } keys %szs )
		{
			$mtxt .= "$sz : $szs{$sz}, " ;
		}
		$mtxt .= " <P>\n" ;
	}

	{
		open my $FHTML, '>', "html/index.html" ;
		print $FHTML $mtxt ;
	}
}


{
  load_size() ;
  load_mark() ;
  say "setup. " ;
  local $|= 1 ;

  open my $LIST, '<', 'db.txt' || die "no db.txt" ;

  for ( <$LIST> )
  {
    my ($typ, $img, $szs)= /(\w+)\s+(i\d+)\s+\(([\w\d\s]++)\)/ ;
    # say "Found $typ $img $szs" ;
    next unless $typ && $szs ;

    print '.' ;

    my $k= process( $img, $typ ) ;
    next unless $k ;
    for ( $szs =~ /(\d+\s+\w+)/g )
    {
      my ($n, $sz)= /(\d+)\s+(\w+)/ ;

      chksz( $sz) ;
      push @{$pages{$typ}{$sz}}, [ $k, $img, $n ] ;
    }
  }

  say "pages" ;
  print_pages() ;

  say "Done." ;
  sleep 2 ;
}
