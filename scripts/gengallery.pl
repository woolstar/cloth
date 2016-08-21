#!/usr/bin/perl -s

  use 5.022 ;
  use vars qw( $folder $nocov $simple ) ;
  use DBI ;

  use File::Copy 'cp' ;
  use Graphics::Magick ;
  use Data::Dumper ;

no warnings "experimental::smartmatch" ;

  my ( %isize, %icover, %ichart, %imark ) ;
  my ( $dbh ) ;

sub open_db
{
    my $dbpath= "../db/" ;
    $dbh= DBI-> connect("dbi:SQLite:dbname=${dbpath}prod.s3db", "", "") ;
    $dbh-> {RaiseError}= 1 if $dbh ;
}

sub load_size
{
  for ( <util/u_size_*.jpg> )
  {
    my ($sz)= /u_size_(\w+)\./ ;
    next unless $sz ;
    my $img= new Graphics::Magick ;
    $img-> Read($_) ;
    $isize{$sz}= $img ;
  }

  $isize{'GEN'}= '' ;
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
  for ( 3, 6 )
  {
    my $fi= "util/c_jeanne_${_}x${_}.tif" ;
    say "FAIL: unable open $fi" && next unless -e $fi ;
    my $img= new Graphics::Magick ;
    $img-> Read($fi) ;
    $imark{$_}= $img ;
  }
}

sub process
{
  my ($path, $i, $sz)= @_ ;

  my $img= new Graphics::Magick ;
  $img-> Read( "../page/img/$i.jpg" ) ;

  my ($x,$y)= $img-> Get('columns', 'height' ) ;
  return unless $y ;

  my ($ix, $iy) ;
  $iy= 960 ;
  $ix= int( $iy * $x / $y + 0.5 ) ;

  $img-> Resize( geometry => "${ix}x${iy}" ) ;
  if ( $sz ne 'GEN' )
  {
    $img-> Composite( image => $isize{$sz},
    		      gravity => 'NorthEast',
		      geometry => '-8-8'
		    ) ;
  }

  ## watermark
  $img-> Composite( Image => $imark{3},
		    gravity => 'SouthEast',
		    geometry => '+16+16'
		  ) ;

  $img-> Flatten() ;
  $img-> Write( $path ) ;
}

{
  my ( %szs, %szrank, %style ) ;

  open_db() ;
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

  my $its_= $dbh-> selectall_arrayref("SELECT name, `count`, item.tags, style_id, sizes_id "
  				      . "FROM item JOIN media USING ( media_id ) "
				      . "WHERE owner_fk = ? AND `count` > 0 ORDER BY style_id, sizes_id ",
				     { Slice=> {} },
				     100
				     ) ;

  say "items ". @$its_ ;

  load_size() ;
  load_cover() ;
  load_mark() ;
  say "setup. " ;
  $|= 1 ;

  my ( $styrec, $sty, $styf, $osty) ;
  for ( @$its_ )
  {
    $styrec= $style{ $_->{style_id}} ;
    $sty= $styrec->{name} ;  $styf= $styrec->{folder} ;

    next if $folder and $folder ne $styf ;

    say "\nStyle $sty " if ( $sty ne $osty ) ;
    $osty= $sty ;

    my ($img, $ct, $szid)= @$_{ qw( name count sizes_id ) } ;
    next unless $ct ;

    my $path= "prepare/" ;  mkdir $path unless -d $path ;
    $path .= "$styf/" ;
    if ( ! -d $path )
    {
      mkdir $path ;
      cp( $icover{$styf}, "$path/0cover.jpg" ) if $styf ~~ %icover ;
      cp( $ichart{$styf}, "$path/0sizing.jpg" ) if $styf ~~ %ichart ;
    }

    my $szrec= $szs{$szid} ;
    unless ( $simple )
	{ $path .= "sz$szrec->{ranking}_$szrec->{code}_$styf/" ;  mkdir $path unless -d $path ; }
    $path .= "im${styf}_sz$szrec->{ranking}$szrec->{code}_$img.jpg" ;

    process( $path, $img, $szrec->{code} ) ; 

    print '.'
  }

  say "\ndone."
}
