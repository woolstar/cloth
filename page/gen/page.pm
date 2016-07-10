
use 5.022 ;

no warnings 'experimental' ;

use gen::file ;
use gen::http ;

require Exporter;
our @ISA = ("Exporter") ;
our @EXPORT = qw(gen_page) ;
our @EXPORT_OK = qw(templ, load_tmpl) ;

  my @headers ;

sub load_templ
{
  my ($fi)= @_ ;
  load_file("html/$fi.html") || load_file("gen/html/$fi.html")
}

sub replace
{
  my ($param, $data_)= @_ ;
  my ($enc, $key, $close)= $param =~ /^([\"\%\&\<])?(.*?)([\"\%\^\>])?$/ ;
  $close =~ tr/>/</ ;
  return if $close && $close ne $enc ;

  my $val= $data_->{$key} ;
  given ( $enc ) {
    return encode_url( $val ) when '%' ;
    return encode_word( $val ) when '&' ;
    return '"' . encode_word( $val ) . '"' when '"' ;
  }

  return $val ;
}

sub templ_replace
{
  my ($src, $data_)= @_ ;

  $src =~ s/{(\S.*?)}/replace($1, $data_)/ge ;
  return $src ;
}

sub row_replace
{
  my ( $src, $k, $data_ )= @_ ;

  $src =~ s/{$k\.(\S.*?)}/replace( $1, $data_ )/ge ;
  return $src ;
}

sub templ
{
  my ($src, $data_)= @_ ;
  my ($doc) ;

  my @parts= split( /(<repeat.*?<\/repeat>)/isg, $src ) ;
  for my $part (@parts)
  {
    if ( my( $k, $bod )= $part =~ /<repeat\s+on=(\S+)>\s*(.*?)<\/repeat>/isg )
    {
      my $recs_= $data_->{$k} ;
      my @txt= map { templ_replace($_, $data_) } map { row_replace( $bod, $k, $_ ) } @$recs_ ;
      $doc .= join('', @txt) ;
      next ;
    }

    $doc .= templ_replace( $part, $data_ ) ;
  }

  return $doc ;
}

sub gen_page
{
  my ( $nam, $data)= @_ ;

  $nam =~ s/[^_0-9a-zA-Z]//g ;
  my $src= load_templ('head') . load_templ($nam) . load_templ('foot') ;

  $data->{_name}= lc $nam || 'empty' ;
  $data->{content_type} ||= 'text/html' ;
  my $doc= templ( $src, $data ) ;

  say "Content-Type: $data->{content_type}" ;
  print join("\n", @headers, 'Content-Length: '. length($doc), undef, $doc) ;
}

sub gen_bare
{
  my ( $txt, @hdrs )= @_ ;

  say "Content-Type: text/html" ;
  print join("\n", @hdrs, 'Content-Length: '. length($txt), undef, $txt ) ;
}

1 ;
