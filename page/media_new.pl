#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page templ load_templ) ;
use gen::dbcloth ;

  no warnings 'experimental::smartmatch' ;

use Data::Dumper ;

sub layout
{
  my ($rec_)= @_ ;

  my $txt= "<IMG " ;
  my $path= $rec_->{path} ;
  $path =~ s(^page/)() ;
  my ($x,$y)= $rec_->{geom} =~ /(\d+)x(\d+)/ ;
  my $sz= 320 ;

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

sub do_update
{
  my ($rec_)= @_ ;
  my %dat ;

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

  $dat{error}= Dumper($rec_) ;
  web_redirect( $rec_->{acct}, $sty ) ;
  exit
}

{
  my %dat ;

  my %args= parse_query($ENV{QUERY_STRING}) ;
  my $u_= get_user( $args{acct}) ;
  %dat= ( %$u_, %args ) ;

  $dat{username}= $u_->{name} ;
  my $sty= $dat{style_id} ;

  $dat{media}= load_newmedia($args{acct}, $sty) ;
  {
    my $styles_= get_styleinfo( $sty ) ;
    @dat{ qw(style_id style_name style_path style_group sizing) }= @$styles_ if $styles_ ;
  }

  my $szlist_= load_sizes( $dat{sizing} ) ;
  for ( @{$dat{media}} )
  {
    $_->{img}= layout( $_ ) ;
  }

  my $css ;
  $css .= 'input.count { width: 4em; } ' ;
  $dat{_head} = '<style type="text/css">'. $css . '</style>' ;

  gen_page('media_new', \%dat) ;
}

