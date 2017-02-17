#!/usr/bin/perl

use 5.022 ;
use gen::page ;
use gen::dbcloth ;
use gen::http qw(parse_query) ;

use Data::Dumper ;

{
  my %dat ;
  my %args= parse_query( $ENV{QUERY_STRING} ) ;
  my $user= $args{acct} ;
  my $u_= get_user( $user ) ;

  %dat = %$u_ ;

  my $cam_ = get_campaigns($user) ;

  $dat{acct}= $user ;
  $dat{camp}= $cam_ ;

  for ( @$cam_ )
  {
    $_->{tagview}= join("<br>", @{$_->{tags}} ) ;
  }
  gen_page('camp_list', \%dat ) ;
}
