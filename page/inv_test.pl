#!/usr/bin/perl

use 5.022 ;
use gen::page qw(gen_page gen_bare templ load_templ) ;
use gen::dbcloth ;
use gen::http qw(parse_query) ;

use experimental 'smartmatch' ;

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
  $pg .= qq(<META http-equiv="refresh" content="0;URL=index.pl?user=$id">) ;
  $pg .+ "</head><body>Updated</body></html>" ;

  gen_bare( $pg ) ;
}

sub reorder
{
  my ($its_)= @_ ;
  my (@first, @zero) ;

  for ( @$its_ )
    { if ( $_->{count} > 0 ) { push @first, $_ } else { push @zero, $_ } }

  push @first, @zero ;
  return \@first ;
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

sub gen_tags
{
  my ($rec_)= @_ ;
  my @tg ;

  if ( $_->{count} ) {
    push @tg, 'normal' ;
    if ( $_->{tags} ) { push @tg, split /\s+/, $_->{tags}  ; }
      else { push @tg, 'plain' }
  }
    else { push @tg, 'empty' }

  return @tg
}

sub gen_category
{
  my ( $list_ , $sel ) = @_ ;

  my $ct = 0 + ( grep { $_->{count} > 0 } @$list_ ) ;
  my $select= $sel || (( $ct > 20 ) ? 'plain' : 'normal' ) ;
  
  my %grps = ( plain => undef, normal => undef, empty => undef ) ;
  for ( @$list_ ) {
    for my $tg ( gen_tags($_) )
      { if ( ! $grps{$tg} ) { $grps{$tg}= [ 1, $_ ] } else { $grps{$tg}[0] ++ } }
  }

  foreach ( grep { ! $grps{$_} } keys %grps ) { delete $grps{$_} }
  my $empty = $grps{empty} ;
  delete $grps{empty} ;

  my @gdata= map { [ $_, @{$grps{$_}} ] } sort { $grps{$b}[0] <=> $grps{$a}[0] } keys %grps ;
  push @gdata, [ 'empty', @$empty ] if $empty ;
  return ( \@gdata, $select )
}

sub is_tag
{
  my ($rec_, $sel)= @_ ;
  my @cat= gen_tags( $rec_ ) ;
  return $sel ~~ @cat
}

sub scale
{
  my ($rec_, $sz)= @_ ;
  my ($x,$y)= $rec_->{geom} =~ /(\d+)x(\d+)/ ;

  if ( $x && $y )
  {
    my ($ix, $iy) ;
    if ( $x > $y ) {
      $ix= $sz ; 
      $iy= int( $sz * $y / $x + 0.5 ) ;
    }
    else {
      $iy= $sz ; 
      $ix= int( $sz * $x / $y + 0.5 ) ;
    }
    return "width=$ix height=$iy" ;
  }
}

sub format_tag
{
  my ( $tg_, $path )= @_ ;

  my $txt ;

  $txt = '<tr>' ;
  for ( @$tg_ ) {
    $txt .= "<td width=70 align=center><a href=\"$path&display=$_->[0]\">$_->[0]</a></td>" ;
  }
  $txt .= "</tr>" ;

  $txt .= '<tr>' ;
  for ( @$tg_ ) {
    $txt .= "<td align=center>$_->[1]</td>" ;
  }
  $txt .= "</tr>" ;

  $txt .= '<tr>' ;
  for ( map { $_->[2] } @$tg_ ) {
    $txt .= "<td align=center><img ". scale($_, 120) ." src=$_->{path} /></td>" ;
  }
  $txt .= "</tr>" ;

  return $txt
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
  $its_= reorder( $its_ ) ;

  my ( @recs, @rz ) ;

  $dat{items}= join(',', map { $_->{item_id} } @$its_ ) ;

  my ( $cats_, $ccat ) = gen_category( $its_, $args{display} ) ;

  my $path= 'inv_test.pl?' . join('&', map { "$_=$dat{$_}" } qw(acct style_id sizes_id) ) ;
  $dat{tags}= format_tag( $cats_, $path ) ;

  for (@$its_ ) {
    next unless is_tag( $_, $ccat ) ;

    $_->{scale}= scale($_, 400) ;
    if ( $_->{count} > 0 ) { push @recs, $_  }
    	else { push @rz, $_ }
  }

  if ( @recs && @rz ) {
    my $r_= $recs[-1] ;
   $r_->{between_}= "<tr><td colspan=99> <BUTTON Name=\"Post\" TYPE=post value=update>Post</BUTTON> <hr><p> </td></tr>\n" ;
    push @recs, @rz ;
  }

  $dat{item}= \@recs ;

  gen_page('item_list', \%dat) ;
}

