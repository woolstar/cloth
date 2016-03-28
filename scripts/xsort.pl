use 5.020 ;
use Image::Magick ;

  no warnings "experimental::smartmatch" ;

my @sz = qw(XXS XS S M L XL 2XL 3XL KS KL TW OS TC) ;
my ( @pass, %stor, @complete ) ;

my $top= 10 ;

sub loadr
{
  my ( $ty, %ksz ) ;
  @ksz{@sz}= undef ;

  open my $FI, '<', 'list.txt' || die "unable to open list.txt" ;
  while ( <$FI> )
  {
    chomp ;
    next unless $_ ;

    if ( /^DSC_\d+/ )
    {
      my ($fi,$szs)= /^(DSC_\d+)\s*(.*)$/ ;
      say "img $_ | $szs" ;
      if ( ! $szs || ("1 _" eq $szs))
      {
	my $fif= "${fi}.JPG" ;
	push @pass, $fif if -e $fif ;
	next ;
      }
      for ( $szs =~ /(\d+\s+\w+)/g )
      {
	my ($n,$sz)= /(\d+)\s+(\w+)/ ;
	die "Unrecognized SZ $fi $sz" unless $sz ~~ %ksz ;
      }
      push @{$stor{$ty}}, [$fi, $szs] ;
    }
    elsif ( /^(\w+)$/ )
    {
      $ty= $_ ;
    }
  }
}

sub readdb
{
	open my $FIDB, '<', '../db.txt' or return ;
	while ( <$FIDB> )
	{
		if ( /i(\d{5})/ ) { $top= $1 +1 if $1 >= $top }
	}
	$top += 1 if $top > 100 ;
}

sub savec
{
  return unless @complete ;

  open my $FO, '>>', '../db.txt' or die "unable to write db" ;
  for ( @complete )
  {
    say $FO $_
  }
}

loadr() ;

if ( @pass )
{
  say "Extra " ;
  for ( @pass ) { rename( $_, "../used/$_" ) }
}

readdb() ;

say "Found" ;
for my $prod ( keys %stor )
{
  say "Product $prod" ;

  for ( @{$stor{$prod}} )
  {
    my $fif= $_->[0] . ".JPG" ;
    die "Could not find $fif" unless -e $fif ;

    my $imgid= sprintf("i%05d", $top) ;

    my $img= new Image::Magick ;
    my ($x, $y) = $img->Get('columns', 'height') ;

    $img-> Read( $fif ) ;

    ## say "All : " . $img-> Get('%[EXIF:*]') ;

    { my ($e) = $img->Get('%[EXIF:orientation]') ;
      say " .. Rotated" if 6 == $e ;
    }
    $img-> AutoOrient() ;
    $img-> Set('%[EXIF:UserComment]', "Jeannes Lularoe $prod - $imgid") ;
    $img-> Set('%[EXIF:Copyright]', "(c) 2016 Jeanne Woolverton") ;
    $img-> Set('%[EXIF:orientation]', 0) ;

    ($x, $y) = $img->Get('columns', 'height') ;
    $img-> Normalize() ;

    my ($newx, $newy) ;
    if ( $x > $y )
    {
	$newx= 1920 ;
	$newy= int( $newx * $y / $x ) ;
    }
    else
    {
	$newy= 1920 ;
	$newx= int( $newy * $x / $y ) ;
    }
    $img-> Resize( geometry => "${newx}x${newy}" ) ;
    $img-> Flatten() ;
    $img-> Write( "../db/${imgid}.jpg" ) ;

    rename( $fif, "../used/$fif" ) ;
    push @complete, "$prod $imgid ($_->[1])" ;
    $top ++ ;
  }
}

savec() ;
