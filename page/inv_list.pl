#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page templ load_templ) ;
use gen::dbcloth ;
use gen::http qw(parse_query) ;

use Data::Dumper ;

our $user= 100 ;

sub layout
{
  my ( $rec_ )= @_ ;
  my $txt= "<IMG " ;
  my $path= $rec_->{path} ;
  $path =~ s(^page/)() ;
  my ($x,$y)= $rec_->{geom} =~ /(\d+)x(\d+)/ ;
  my $sz= 128 ;
  if ($x && $y)
  {
    my ( $ix, $iy ) ;
    if ( $x > $y ) { $ix= $sz, $iy= int( $sz * $y / $x + 0.5 ) }
    	else { $iy= $sz, $ix= int( $sz * $x / $y + 0.5 ) }

    $txt .= "width=$ix height=$iy " ;
  }
  $txt .= qq{src= "$path" > } ;
  return $txt
}

{
  my %dat ;
  my %args= parse_query( $ENV{QUERY_STRING} ) ;
  my $u_= get_user( $args{acct} ) ;

  %dat= ( %$u_, %args ) ;
  my $style_id= $args{style_id} ;

  my $sty_= get_styles() ;
  my $inv_= load_inventory( $user, "AND style_id= $style_id " ) ;

  $inv_= $inv_->{$style_id} ;
  $dat{style}= $sty_->{$style_id}{name} ;

  my $css ;
  $css .= 'td { font-size: 16pt; } ' ;
  $css .= 'td.sz { font-size: 18pt; color: white; background-color: black } ' ;
  $dat{_head} = '<style type="text/css">'. $css . '</style>' ;

  my $it_= load_items( @args{ qw(acct style_id) } ) ;

  my @rec ;
  my $ttt ;
  for ( grep { $_->{count} } @$inv_ )
  {
    my $n= 4 ;
    my $imgs ;
    $ttt += $_->{count} ;

    for ( @{$it_->{$_->{sizes_id}}} ) {
      $imgs .= layout( $_ ) ;
      last unless --$n ;
    }

    $_->{img}= $imgs ;
    push @rec, $_ ;
  }

  $dat{inv}= \@rec ;
  $dat{total}= $ttt ;

  gen_page('inv_list', \%dat) ;
}

