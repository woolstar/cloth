
use 5.022 ;

require Exporter;
our @ISA = ("Exporter") ;
our @EXPORT = qw(get_cookie set_cookie) ;

sub get_cookie
{
  my ( $nam, $val )= @_ ;

  for (split(/;\s*/, $ENV{HTTP_COOKIE}))
    { last if ($val) = /^$nam=(.*)$/ ; }

  $val
}

sub set_cookie
{
  my ( $nam, $val )= @_ ;
  my ( $host )= $ENV{HTTP_HOST} =~ /([^\.]+\.[a-z]+)$/i ;

  return ( $domain ) ? "Set-Cookie: $nam=$val; domain=$host; path=/; expires=Tue, 31-Dec-2024 22:00:00 GMT" 
		     : "Set-Cookie: $nam=$val; path=/; expires=Tue, 31-Dec-2024 22:00:00 GMT" 
} 

1 ;
