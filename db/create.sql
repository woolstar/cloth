
CREATE TABLE image
(
	id integer primary key asc,
	len int,
	x int,
	y int,
	dtcreate,
	hash char(40),
	path varchar(128)
) ;

create TABLE picture
{
	id integer primary key asc,
	image_id integer,
	prod_style varchar(64),
	prod_size varchar(64),
	tags varchar(128)
} ;

