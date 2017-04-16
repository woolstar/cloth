
use 5.022 ;

use gen::db ( db => 'prod.s3db' ) ;

require Exporter;
our @ISA = ("Exporter") ;
our @EXPORT = qw(get_user get_styles get_size get_media get_campaigns load_inventory load_items load_style sth_item) ;

sub get_user
{
  my ( $id )= @_ ;
  my %rec ;
  @rec{ qw( user name ) }= $dbh->selectrow_array("SELECT `user`, name FROM identity WHERE id = ?", undef, $id ) ;

  return \%rec
}

sub get_styles
{
  my %sty ;
  for ( @{ $dbh-> selectall_arrayref("SELECT style_id, name, folder FROM style", { Slice => {} }) } )
  {
    my $sty= $_->{folder} || lc $_->{name} ;
    $_->{code}= $sty ;
    $sty{$_->{style_id}}= $_ ;
  }

  return \%sty
}

sub get_size
{
  my ($id)= @_ ;
  my ($label)= $dbh->selectrow_array("SELECT label FROM sizes WHERE sizes_id = ?", undef, $id ) ;

  return $label
}

sub get_newmedia
{
  my ($id)= @_ ;
  
  return { @{ $dbh-> selectcol_arrayref( "SELECT style_id, count(*) as ct "
  			      	      . "FROM media WHERE owner_id= ? AND tags='GEN' GROUP BY 1",
				      { Columns => [1, 2] }, $id
				    ) } }
}

sub get_media
{
  my ($id)= @_ ;

  return $dbh->selectrow_arrayref(
  		 "SELECT media_id, med.name AS name, path, geom, style_id, ispublic, tags, sty.name AS style, sizing "
		 . "FROM media AS med JOIN style AS sty USING ( style_id ) WHERE media_id= ?",
  		 undef, $id ) ;
}

sub get_styleinfo
{
  my ($id)= @_ ;

  return $dbh->selectrow_arrayref(
  		 "SELECT style_id, `name`, `folder`, `group`, sizing FROM style WHERE style_id= ?",
		 undef, $id
	       ) ;
}

sub get_campaigns
{
  my ($id)= @_ ;
  my @cmpg ;

  for ( @{ $dbh-> selectall_arrayref( "SELECT name, tags as tagstr, styles as stylestr, art_prefix, isactive "
				      . "FROM campaign WHERE owner_fk = ? ORDER BY isactive DESC, name ASC",
				      { Slice => {} },
				      $id
				    ) } )
  {
    $_->{tags}= [ split /\s+/, $_->{tagstr} ] ;
    $_->{styles}= [ split /\s+/, $_->{stylestr} ] ;
    push @cmpg, $_ ;
  }
  
  return \@cmpg ;
}

sub load_sizes
{
  my ($id )= @_ ;
  return $dbh-> selectall_arrayref( "SELECT sizes_id, code, label FROM sizing JOIN sizes USING (sizes_id) WHERE name = ? ",
  				    { Slice=> {} },
				    $id
				  ) ;
}

sub load_inventory
{
  my ( $id, $wher )= @_ ;
  my %rec ;

  $wher //= '' ;

  for ( @{ $dbh-> selectall_arrayref(
		  "SELECT style_fk AS style_id, sz.sizes_id AS sizes_id, sz.label AS sz, sum(`count`) AS count "
		  . "FROM item JOIN sizes AS sz USING ( sizes_id ) "
		  . "WHERE owner_fk = ? $wher GROUP BY 1, 2 ORDER BY 1, sz.ranking",
		  { Slice => {} },
		  $id
		) } )
    { push @{$rec{$_->{style_id}}}, $_ }

  return \%rec
}

sub load_newmedia
{
  my ( $own, $id ) = @_ ;

  return $dbh-> selectall_arrayref(
  		  "SELECT media_id, name, `path`, geom, style_id, isactive, tags "
		  . "FROM media WHERE owner_id=? AND style_id=? AND tags='GEN' ORDER BY 2",
		  { Slice => {} },
		  $own, $id
		) ;
}

sub load_olditems
{
  my ($own, $sty) = @_ ;

  return $dbh-> selectall_arrayref(
		  "SELECT id AS item_id, media_id, name, geom, path "
		  . "FROM item JOIN media USING ( media_id ) "
		  . "WHERE owner_fk = ? AND style_fk = ? AND count = 0 ",
		  { Slice => {} },
		  $own, $sty
		) ;
}

sub load_items
{
  my %rec ;
  for ( @{ $dbh-> selectall_arrayref(
  		  "SELECT sizes_id, id AS item_id, media_id, name, geom, path "
		  . "FROM item JOIN media USING ( media_id ) "
		  . "WHERE owner_fk = ? AND style_fk = ? AND count > 0 ",
		  { Slice => {} },
		  @_ 
		) } )
    { push @{$rec{$_->{sizes_id}}}, $_ }

  return \%rec
}

sub load_media_item
{
  my %rec ;
  for ( @{ $dbh-> selectall_arrayref(
  		  "SELECT sizes_id, id AS item_id, `count`, tags "
		  . "FROM item WHERE owner_fk = ? AND style_fk = ? AND media_id = ? ",
		  { Slice => {} },
		  @_ 
		) } )
    { $rec{$_->{sizes_id}}= $_ }

  return \%rec
}

sub load_item
{
  return $dbh-> selectall_arrayref(
		  "SELECT id AS item_id, media_id, name, geom, path, count, it.tags AS tags "
		  . "FROM item AS it JOIN media USING ( media_id ) "
		  . "WHERE owner_fk = ? AND style_fk = ? AND sizes_id = ? ORDER BY tags", 
		  { Slice => {} },
		  @_
		) ;

}

sub db_clearcounts
{
  my ( $id, $sty )= @_ ;

  return $dbh-> do( "UPDATE item SET `count`=0 WHERE owner_fk= ? AND style_fk= ?", 
		    undef, $id, $sty 
		  ) ;
}

sub db_clearitem
{
  my ( $id, $media )= @_ ;
  return $dbh-> do( "DELETE FROM item WHERE owner_fk = ? AND media_id = ? AND `count` = 0",
  		    undef, $id, $media
		  ) ;
}

sub media_nogen
{
  my ($id)= @_ ;
  $dbh-> do( "UPDATE media SET tags='' WHERE media_id= ?", undef, $id ) ;
}

sub sth_item
{
  my ($id)= @_ ;

  return $dbh-> prepare( "UPDATE item SET `count`=?, tags=? WHERE id = ? AND owner_fk = $id " ) ;
}

sub sth_itim
{
  my ($id)= @_ ;

  return $dbh-> prepare( "INSERT INTO item (media_id, sizes_id, style_fk, owner_fk, `count`, tags ) VALUES (?, ?, ?, $id, ?, ?)" ) ;
}

1 ;
