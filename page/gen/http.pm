
use 5.022 ;

  use vars qw(%query %qwery) ;

require Exporter;
our @ISA = ("Exporter") ;
our @EXPORT = qw(encode_url decode_url encode_word decode_word parse_query) ;
our @EXPORT_OK = qw(pack_query %query %qwery encode_choice) ;

sub encode_url
{
  my ($s)= @_ ;
  $s =~ s/([\x00-\x20\#\%\&\'\+\/\=\?\x80-\xff])/"%".unpack('H2',$1)/ge ;
  $s
}

sub decode_url
{
  my ($s)= @_ ;
  $s =~ s/\+/ /g ;
  $s =~ s/%(..)/pack('H2',$1)/ge ;
  $s
}

sub encode_word
{
  my ($s)= @_ ;
  $s =~ s/&/&amp;/g ;
  $s =~ s/\"/&quot;/g ;
  $s =~ s/</&lt;/g ;
  $s =~ s/>/&gt;/g ;
  $s
}
      
sub decode_word
{
  my ($s)= @_ ;
  $s =~ s/&gt;/>/g ;
  $s =~ s/&lt;/</g ;
  $s =~ s/&quot;/\"/g ;
  $s =~ s/&amp;/&/g ;
  $s
}

sub encode_choice
{
	my ( $na, $lst_, $sel )= @_ ;
	my $txt ;

	for ( @$lst_ )
	{
		my ( $k, $v ) = %$_ ;
		$txt .= " <option value=\"" . encode_url( $k ) . "\">" . encode_word( $v ) . "</option>\n" ;
	}

	return "<select name=$na>\n" . $txt . "</select>" ;
}


sub parse_query
{
  for ( @_ )
  {
    next if ref $_ eq 'HASH' ;
    for ( split(/&/ ) )
    {
      my ($k, $val) ;
      if ( /^(.*?)=(.*)$/ )
	  { ($k, $val)= map { decode_url( $_ ) } ( $1, $2 ) }
	else { $k= decode_url( $_ ), $val= 1 ; }

      $query{$k}= $val ;
      $qwery{$k}{$val}= undef ;
    }
  }

  return %query
}

sub pack_query
{
  my ( $data_ )= @_ ;

  $data_->{query}= '?' . join('&', map { "$_=". encode_word($query{$_}) } grep { $query{$_} } keys %query ) ;
  $data_->{qwery}= '?' . join('&', map { my $k= $_ ; map { "$k=". encode_word($_) } keys %{$qwery{$k}} } keys %qwery ) ;
}

1 ;
