#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page templ load_templ) ;
use gen::http 'encode_choice' ;
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

  my $sth_ins= sth_itim($rec_->{acct}) ;
  my $sty= $rec_->{style_id} ;
  my $sz= $rec_->{sizing} ;

  for ( grep { /item_\d/ } keys %$rec_ )
  {
	my ($d)= /(\d+)/ ;
	next unless $d ;
	$sth_ins-> execute( $d, $sz, $sty, 1, '' ) ;
	media_nogen( $d ) ;
  }
}

{
  my %dat ;

  my %args= parse_query($ENV{QUERY_STRING}) ;
  my $u_= get_user( $args{acct}) ;
  %dat= ( %$u_, %args ) ;

  $dat{username}= $u_->{name} ;
  my $sty= $dat{style_id} ;

  do_update( \%dat ) if $args{action} eq 'update' ;

  $dat{media}= load_newmedia($args{acct}, $sty) ;
  {
    my $styles_= get_styleinfo( $sty ) ;
    @dat{ qw(style_id style_name style_path style_group sizing) }= @$styles_ if $styles_ ;
  }

  {
	my $sizes_= load_sizes( $dat{sizing} ) ;
	my @choice = map { { $_->{sizes_id} => $_->{ label } } }
				 sort { $a->{sizes_id} <=> $b->{sizes_id} } @$sizes_ ;

	$dat{ style_sel } = encode_choice( "sizing", \@choice ) ;
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

