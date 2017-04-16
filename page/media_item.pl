#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page templ load_templ) ;
use gen::dbcloth ;

  no warnings 'experimental::smartmatch' ;

use Data::Dumper ;

sub web_redirect
{
  my ($id, $styi, $link)= @_ ;

  my $pg= "<html><head>" ;
  $pg .= qq(<META http-equiv="refresh" content="0;URL=$link.pl?acct=$id&style_id=$styi">) ;
  $pg .+ "</head><body>Updated</body></html>" ;

  gen_bare( $pg ) ;
}

sub layout
{
  my ($rec_)= @_ ;

  my $txt= "<IMG " ;
  my $path= $rec_->{path} ;
  $path =~ s(^page/)() ;
  my ($x,$y)= $rec_->{geom} =~ /(\d+)x(\d+)/ ;
  my $sz= 640 ;

  if ( $x && $y )
  {
    my ( $ix, $iy ) ;
    if ( $x > $y ) { $ix= $sz, $iy= int( $sz * $y / $x + 0.5 ) }
        else { $iy= $sz, $ix= int( $sz * $x / $y + 0.5 ) }

    $txt .= "width=$ix height=$iy " ;
  }
  $txt .= qq{src= "$path" > } ;
  return $txt
}

sub do_clear
{
  my ($rec_)= @_ ;

  my $acct= $rec_->{acct} ;
  db_clearitem( $acct, $rec_->{media_id} ) ;

  web_redirect( $acct, $rec_->{style_id}, 'inv_list' ) ;
  exit
}

sub do_update
{
  my ($rec_)= @_ ;

  my $sth_up= sth_item($rec_->{acct}) ;
  my $sth_ins= sth_itim($rec_->{acct}) ;

  my $sty= $rec_->{style_id} ;
  for ( split /,/, $rec_->{sizes} )
  {
    my $sz= "size_$_" ;
    my ( $ct, $tags, $id )= @$rec_{ "${sz}_count", "${sz}_tags", "${sz}_id" } ;

    if ( $id ) { $sth_up-> execute( $ct, $tags, $id ) }
    	else { $sth_ins-> execute( $rec_->{media_id}, $_, $sty, $ct, $tags ) if $ct || $tags }
  }

  if ( $rec_->{gen} )
  {
    media_nogen($rec_->{media_id}) ;
    web_redirect( $rec_->{acct}, $sty, 'media_new' ) ;
  }
  else
  {
    web_redirect( $rec_->{acct}, $sty, 'inv_list' ) ;
  }

  exit
}

{
  my %dat ;

  my %args= parse_query($ENV{QUERY_STRING}) ;
  my $u_= get_user( $args{acct}) ;
  %dat= ( %$u_, %args ) ;
  $dat{username}= $u_->{name} ;

  do_clear( \%args) if $args{Clear} ;
  do_update( \%args ) if $args{sizes} ;

  {
    my $media_= get_media( $args{media_id} ) ;
    @dat{ qw(media_id name path geom style_id ispublic tags style sizing) }= @$media_ if $media_ ;
  }

  $dat{gen}= 1 if $dat{tags} eq 'GEN' ;

  my $szlist_= load_sizes( $dat{sizing} ) ;
  my $its_ = load_media_item( @dat{ qw(acct style_id media_id ) } ) ;

  my @ky= qw( item_id count tags ) ;
  for ( @$szlist_ )
  {
    @$_{@ky}= @{$its_->{$_->{sizes_id}}}{@ky} if $_->{sizes_id} ~~ %$its_ ;
    $_->{item_id} //= 0 ;
  }

  my $css ;
  $css .= 'td.sz { font-size: 8pt; color: white; background-color: black } ' ;
  $css .= 'input.count { width: 4em; } ' ;

  $dat{_head} = '<style type="text/css">'. $css . '</style>' ;

  $dat{img}= layout( \%dat ) ;
  $dat{sizes}= join(',', map { $_->{sizes_id} } @$szlist_ ) ;
  $dat{szs}= $szlist_ ;

  gen_page('media_item', \%dat) ;
}

