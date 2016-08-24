#!/usr/bin/perl

use 5.022 ;
use gen::page ;
use gen::dbcloth ;
use gen::http qw(parse_query) ;

	no warnings 'experimental::smartmatch' ;

use Data::Dumper ;

sub redir
{
  my ($link, $param) = @_ ;

  my $pg= "<html><head>" ;
  $pg .= qq(<META http-equiv="refresh" content="0;URL=$link$param">) ;
  $pg .+ "</head><body>Updated</body></html>" ;

  gen_bare( $pg ) ;
  exit
}

sub doclear
{
  my ($ref_)= @_ ;

  my ($id, $sty)= @$ref_{qw(acct style_id)} ;
  db_clearcounts( $id, $sty ) ;

  redir('index.pl', "?acct=$id") ;
}

{
  my %dat ;
  my %args= parse_query( $ENV{QUERY_STRING} ) ;
  my $u_= get_user( $args{acct} ) ;

  my $idtxt= "?acct=$args{id}" ;

  for ( $args{action} )
  {
	doclear(\%args) when /clear/ ;
	redir('index.pl', $idtxt) when undef ;
  }

  exit ;
}

