#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page templ load_templ) ;
use gen::dbcloth ;

use Data::Dumper ;

  no warnings 'experimental::smartmatch' ;


our $user= 100 ;

{
  my %dat ;
  my $u_= get_user( $user) ;

  %dat= %$u_ ;

  my $sty_= get_styles() ;
  my $inv_= load_inventory( $user ) ;
  # $dat{data}= Dumper($inv_) ;
  
  $dat{acct}= $user ;
  my $news_= get_newmedia( $user ) ;

  my $css ;
  $css .= 'td.sz { font-size: 8pt; color: white; background-color: black } ' ;
  $css .= 'td.lead { font-size: 14pt; } ' ;
  $css .= 'td.total { font-size: 13pt; } ' ;
  $dat{_head} = '<style type="text/css">'. $css . '</style>' ;

  my $row_tmpl= load_templ('home_row') ;

  my @inv ;
  my $ttt ;
  for ( sort { $sty_->{$a}{code} cmp $sty_->{$b}{code} } keys %$inv_ )
  {
    my %rec ;
    $rec{style_id}= $_ ;
    $rec{style}= $sty_->{$_}{name} ;
    $rec{news}= qq(<A href="media_new.pl?acct=$user&style_id=$_">$news_->{$_}</A>) if $_ ~~ %$news_ ;
    my $tt= 0 ;
    for ( @{$inv_->{$_}} ) { $tt += $_->{count} }
    $rec{total}= $tt ;
    $ttt += $tt ;
    $rec{row}= templ( $row_tmpl, { size => $inv_->{$_} } ) ;

    push @inv, \%rec ;
  }
  $dat{inv}= \@inv ;
  $dat{total}= $ttt ;

  gen_page('home', \%dat) ;
}

