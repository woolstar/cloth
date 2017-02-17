#!/usr/bin/perl -s

  use 5.018 ;
no warnings "experimental::smartmatch" ;

  use vars qw ( $folder $nocov $szf ) ;
  use DBI ;

  use File::Copy 'cp' ;
  use Graphics::Magick ;

my ( $dbh ) ;
my ( %iparts, %isparts, %icover, %ichart, %imark, %icamp, %icamppre ) ;
my ( %szs, %szrank, %style ) ;

sub open_db
{
  my $dbpath= "../db/" ;
  $dbh= DBI-> connect("dbi:SQLite:dbname=${dbpath}prod.s3db", "", "") ;
  $dbh-> {RaiseError}= 1 if $dbh ;
}

sub open_img
{
  my ( $fi, $na ) = @_ ;

  die "Unable to open $na : $fi" unless -e $fi ;
  my $img= new Graphics::Magick ;
  $img-> Read($fi) ;
  return $img ;
}

sub load_parts
{
  for ( <util/u*_*.jpg> )
  {
    my ( $spcl, $ty, $val )= /u(\w*)_([a-z]+)_(\w+)\./ ;
    next unless $ty && $val ;
    my $img= new Graphics::Magick ;
    $img-> Read($_) ;
    if ( $spcl ) { $isparts{ "u$spcl" }{$ty}{$val}= $img ; }
    	else { $iparts{$ty}{$val}= $img ; }
  }

      ## side mark
  $iparts{'strip'}= open_img( 'util/link_strip.jpg', 'strip' ) ;

      ## filler
  $iparts{'size'}{'GEN'}= undef ;
}

sub load_cover
{
  for ( <util/cover_*.jpg> )
  {
    my ($typ)= /cover_(\w+)\./ ;
    next unless $typ ;
    $icover{$typ}= $_ unless $nocov ;
  }
  for ( <util/sizingchart_*.jpg> )
  {
    my ($typ)= /sizingchart_(\w+)\./ ;
    next unless $typ ;
    $ichart{$typ}= $_ unless $nocov ;
  }
}

sub load_mark
{
  $imark{ '3B' }= open_img( 'util/c_jeanne_3x3.tif', 'mark' ) ;
  $imark{ '3W' }= open_img( 'util/cw_jeanne_3x3.tif', 'mark' ) ;
}

sub load_tables
{
  for ( @{ $dbh-> selectall_arrayref("SELECT sizes_id, code, ranking FROM sizes",  { Slice=> {} }) } )
  {
    $szs{$_->{sizes_id}}= $_ ;
    $szrank{ $_->{code} }= $_->{ranking } ;
  }
  for ( @{ $dbh-> selectall_arrayref("SELECT style_id, `name`, `folder` FROM style",  { Slice=> {} }) } )
  {
    $_->{folder} //= lc $_->{name} ;
    $style{$_->{style_id}}= $_
  }
}

sub load_campaigns
{
  for ( @{ $dbh-> selectall_arrayref("SELECT name, tags, styles, art_prefix FROM campaign WHERE owner_fk= 100 AND isactive = 1",
				      { Slice => {} }
				    ) } )
  {
    # say "Campaign $_->{name} : $_->{styles} " ;
    if ( $_->{styles} )
	{ for my $sty ( split /\s+/, $_->{styles} ) { $icamp{$sty}{$_->{tags}}= $_->{name} } }
	else { $icamp{''}{$_->{tags}}= $_->{name} }
    $icamppre{$_->{name}}= $_->{art_prefix} if $_->{art_prefix} ;
  }
}

sub find_campaign
{
  my ( $sty, $tg )= @_ ;
  return $icamp{$sty}{$tg} || $icamp{''}{$tg} ;
}

##

sub iblank
{
  my ( $g )= @_ ;

  my $i= new Graphics::Magick ;
  $i-> Set( size => $g ) ;
  $i-> ReadImage( 'xc:white' ) ;
  return $i ;
}

sub oldprocess
{
  my ( $path, $i, $sz, $sty )= @_ ;

  my $img= new Graphics::Magick ;
  $img-> Read( "../page/img/$i.jpg" ) ;

  my ($x,$y)= $img-> Get('columns', 'height' ) ;
  return unless $y ;

  my ($ix, $iy) ;
  $iy= 960 ;
  $ix= int( $iy * $x / $y + 0.5 ) ;

  $img-> Resize( geometry => "${ix}x${iy}" ) ;

  # watermark
  $img-> Composite( image => $imark{ '3W' }, gravity => "SouthWest", geometry => "+32+32" ) ;
  $img-> Flatten() ;
  $img-> Write( $path ) ;
}

sub process
{
  my ( $path, $i, $sz, $sty, $prefix )= @_ ;

  return oldprocess( $path, $i, $sz, $sty ) if ( 'combo' eq $sty ) || ! ( $sz ~~ %{$iparts{'size'}} ) ;

  my $isrc= new Graphics::Magick ;
  $isrc-> Read( "../page/img/$i.jpg" ) ;

  my ($x,$y)= $isrc-> Get('columns', 'height' ) ;
  return unless $y ;

  my $imid= iblank( '260x542' ) ;
  if (( 'leggings' eq $sty ) || ('kleggings' eq $sty ))
      { $imid-> Composite( image => $isrc, gravity => 'Center', geometry => "-330-320" ) }
    else { $imid-> Composite( image => $isrc, gravity => 'Center' ) ; }

  my ($ix, $iy) ;
  $iy= 960 ;
  $ix= int( $iy * $x / $y + 0.5 ) ;

  $isrc-> Resize( geometry => "${ix}x${iy}" ) ;
  my $img= iblank( "896x960" ) ;

  $img-> Composite( image => $isrc, gravity => 'West' ) ;
  $img-> Composite( image => $iparts{'strip'}, gravity => 'East' ) ;

  my $isty= $iparts{'sty'}{$sty} ;
  $isty= $isparts{$prefix}{'sty'}{$sty} if $prefix && $isparts{$prefix} && $isparts{$prefix}{'sty'}{$sty} ;

  $img-> Composite( image => $isty, gravity => 'NorthEast', geometry => '+44-0' ) ;
  $img-> Composite( image => $iparts{'size'}{$sz}, gravity => 'NorthEast', geometry => '+44+109' ) ;

  my $iprice= $iparts{'price'}{$sty . lc $sz} || $iparts{'price'}{$sty} ;
  $iprice= $isparts{$prefix}{'price'}{$sty} if $prefix && $isparts{$prefix} && $isparts{$prefix}{'price'}{$sty}  ;
  $img-> Composite( image => $iprice, gravity => 'NorthEast', geometry => '+44+309' ) ;

  $img-> Composite( image => $imid, gravity => 'SouthEast', geometry => '+44-0' ) ;

  # watermark
  $img-> Composite( image => $imark{ '3W' }, gravity => "SouthWest", geometry => "+32+32" ) ;

  $img-> Flatten() ;
  $img-> Write( $path ) ;
}

##

{
  open_db() ;

  load_parts() ;
  load_cover() ;
  load_mark() ;
  load_tables() ;
  load_campaigns() ;

  my $its_= $dbh-> selectall_arrayref("SELECT name, `count`, item.tags as tags, style_id, sizes_id "
                                      . "FROM item JOIN media USING ( media_id ) "
                                      . "WHERE owner_fk = ? AND `count` > 0 ORDER BY style_id, sizes_id ",
                                     { Slice=> {} },
                                     100
                                     ) ;

  say "Folder: $folder" ;
  say "items ". @$its_ ;
  $|= 1 ;

  my ( $styrec, $sty, $styf, $osty ) ;
  for ( @$its_ )
  {
    $styrec= $style{ $_->{style_id}} ;
    $sty= $styrec->{name} ;  $styf= $styrec->{folder} ;

    next if $folder and $folder ne $styf ;

    say "\nStyle $sty " if ( $sty ne $osty ) ;
    $osty= $sty ;

    my ($img, $ct, $szid)= @$_{ qw( name count sizes_id ) } ;
    next unless $ct ;

    my $path= "prepare" ;  mkdir $path unless -d $path ;
    $path .= "/$styf" ;
    if ( ! -d $path )
    {
      mkdir $path ;
      # cp( $icover{$styf}, "$path/0cover.jpg" ) if $styf ~~ %icover ;
      cp( $ichart{$styf}, "$path/0sizing.jpg" ) if $styf ~~ %ichart ;
    }

    my $cmp ;
    if ( $_->{tags} )
    {
      for my $tg ( map { lc } split /\s+/, $_->{tags} )
      {
	$cmp //= find_campaign($_->{style_id}, $tg) ;
      }
    }

    my $szrec= $szs{$szid} ;
    if ( $szf ) {
      $path .= "/sz$szrec->{ranking}_$szrec->{code}_$styf" ;
      $path .= "_$cmp" if $cmp ;
      mkdir $path unless -d $path
    }
    else
    {
      $path .= "_$cmp" if $cmp ;
      mkdir $path unless -d $path
    }
    $path .= "/im${styf}_sz$szrec->{ranking}$szrec->{code}_$img.jpg" ;

    process( $path, $img, $szrec->{code}, $styf, $icamppre{$cmp} ) ;
    print '.'
  }

  say "\ndone."
}

