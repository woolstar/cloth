#!/usr/bin/perl
#
  use 5.016 ;

  use DBI ;
  no warnings 'experimental::smartmatch' ;

  my $dbh ;
  my ( %sty, %szs, %img ) ;

sub load_file
{ 
  my($filename, $data) = @_;
  local($/, *IN);
  if (open(IN, $filename))
  {
    $data = <IN>;
    close IN;
  }
  $data;
}   
  
sub setupdb
{
  $dbh = DBI->connect("dbi:SQLite:dbname=test1.sldb","","") || die "no db" ;
}

sub setupdata
{
  for ( @{ $dbh-> selectall_arrayref("SELECT id, name, folder FROM style", { Slice => {} }) } )
  {
    my $sty= $_->{folder} || lc $_->{name} ;
    $sty{$sty}= $_->{id} ;
  } 

  %szs= @{ $dbh-> selectcol_arrayref("SELECT `code`, id FROM sizes", { Columns => [1, 2] }) } ;
  %img= @{ $dbh-> selectcol_arrayref("SELECT name, id FROM media WHERE ownerid = 100", { Columns => [1, 2] }) } ;
}

sub check_inv
{
  my @rec ;

  chdir( "/cygdrive/u/a/dev/web/tmp" ) ;
  my @rec ;

  open my $LIST, '<', 'db.txt' || die "no db.txt" ;
  for ( <$LIST> )
  {
    my ($typ, $img, $szs)= /(\w+)\s+(i\d+)\s+\(([\w\d\s]++)\)/ ;
    next unless $typ ;

    die "mismatch line $_" unless ( $typ ~~ %sty ) && ( $img ~~ %img ) ;
    for ( $szs =~ /(\d+\s+\w+)/g )
    {
      my ($n, $sz)= /(\d+)\s+(\w+)/ ;
      die "mismatch line size $_ : $sz" unless ( $sz ~~ %szs ) ;

      push @rec, [ $img{$img}, $szs{$sz}, $sty{$typ}, 100, $n, '' ] ;
    }
  }

  return unless @rec ;
  say STDERR "prep." ;
  my $sth= $dbh->prepare( "INSERT INTO item (media_id, sizes_id, style_fk, owner_fk, count, tags) "
  			  . "VALUES (?,?,?,?,?,?)"
			) ;

  for ( @rec ) { $sth-> execute( @$_ ) }
}

{
  setupdb() ;
  setupdata() ;

  check_inv() ;
}

