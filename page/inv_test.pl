#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page gen_bare templ load_templ) ;
use gen::dbcloth ;
use gen::http qw(parse_query) ;

use Data::Dumper ;

sub web_redirect
{
  my ($id, $styi)= @_ ;

  my $pg= "<html><head>" ;
  $pg .= qq(<META http-equiv="refresh" content="0;URL=inv_list.pl?acct=$id&style_id=$styi">) ;
  $pg .+ "</head><body>Updated</body></html>" ;

  gen_bare( $pg ) ;
}

sub web_redirect_home
{
  my ($id)= @_ ;

  my $pg= "<html><head>" ;
  $pg .= qq(<META http-equiv="refresh" content="0;URL=home_pg.pl?user=$id">) ;
  $pg .+ "</head><body>Updated</body></html>" ;

  gen_bare( $pg ) ;
}

sub do_update
{
  my ( $rec_ )= @_ ;
  my %dat ;
  my $err ;

  my $sth= sth_item( $rec_->{acct} ) ;

  for ( split /,/, $rec_->{items} )
  {
    my $it= "item_$_" ;
    my ($ct, $tg)= @$rec_{"${it}_count", "${it}_tag"} ;

    $err .= "item $it, $ct, $tg ; " ;
    $sth-> execute( $ct, $tg, $_ ) ;
  }

  $dat{error}= $err ;

  web_redirect( $rec_->{acct}, $rec_->{style_id} ) if $rec_->{listed} ;
  web_redirect_home( $rec_->{acct} ) ;
  # gen_page('inv_test', \%dat) ;
  exit
}

{
  my %dat ;

  my %args= parse_query($ENV{QUERY_STRING}) ;
  my $u_= get_user( $args{acct}) ;
  %dat= ( %$u_, %args ) ;

  do_update(\%args) if $args{items} ;

  my $sty_= get_styles() ;
  my $st_= $sty_->{$args{style_id}} ;
  $dat{style}= $st_->{name} ;
  $dat{sizelabel}= get_size( $args{sizes_id} ) ;

  my $css ;
  $css .= 'td.sz { font-size: 8pt; color: white; background-color: black } ' ;
  $css .= 'td.lead { font-size: 14pt; } ' ;
  $css .= 'input.count { width: 4em; } ' ;
  $dat{_head} = '<style type="text/css">'. $css . '</style>' ;

  my $its_= load_item( @args{ qw( acct style_id sizes_id ) } ) ;
  my @recs ;

  $dat{items}= join(',', map { $_->{item_id} } @$its_ ) ;

  for (@$its_ ) {
    my $img= $_->{path} ;
    $img =~ s(^page/)() ;
    $_->{img}= $img ;
    my ($x,$y)= $_->{geom} =~ /(\d+)x(\d+)/ ;
    if ( $x && $y )
    {
      my ($ix, $iy) ;
      if ( $x > $y ) {
      	$ix= 400 ; 
	$iy= int( 400 * $y / $x + 0.5 ) ;
      }
      else {
      	$iy= 400 ; 
	$ix= int( 400 * $x / $y + 0.5 ) ;
      }
      $_->{scale}= "width=$ix height=$iy" ;
    }

    push @recs, $_ ;
  }
  $dat{item}= \@recs ;

  gen_page('inv_test', \%dat) ;
}

