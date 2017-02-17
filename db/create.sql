
CREATE TABLE IF NOT EXISTS
  identity
  (
    id INTEGER PRIMARY KEY,
    user,
    name,
    auth,
    authty
  ) ;

INSERT INTO identity (id, user, name, auth, authty ) VALUES ( 100, 'nylulagirl', 'Jeanne Woolverton', 'a15f80401240607f', 3 ) ;

CREATE TABLE IF NOT EXISTS
  auth_type
  (
    authid INT,
    label
  ) ;

INSERT INTO auth_type (authid, label) VALUES ( 0, 'nil' ) ;
INSERT INTO auth_type (authid, label) VALUES ( 1, 'pass' ) ;
INSERT INTO auth_type (authid, label) VALUES ( 2, 'facebook' ) ;
INSERT INTO auth_type (authid, label) VALUES ( 3, 'cert' ) ;

CREATE TABLE IF NOT EXISTS
  style
  (
    style_id INTEGER PRIMARY KEY,
    `name`,
    `folder`,
    `group`,
    sizing
  ) ;

CREATE TABLE IF NOT EXISTS
  sizing
  (
    name,
    sizes_id
  ) ;

CREATE TABLE IF NOT EXISTS
  sizes
  (
    sizes_id INTEGER PRIMARY KEY,
    code,
    label,
    ranking INTEGER
  ) ;

CREATE UNIQUE INDEX IF NOT EXISTS klabel ON sizes (label) ;

CREATE TABLE IF NOT EXISTS
  media_type
  (
    mediatype INT,
    label
  ) ;

INSERT INTO media_type (mediatype, label) VALUES ( 1, 'jpeg' ) ;
INSERT INTO media_type (mediatype, label) VALUES ( 2, 'png' ) ;

CREATE TABLE IF NOT EXISTS
  media
  (
    media_id INTEGER PRIMARY KEY,
    name,
    path,
    geom,
    sha256,
    mediatype INTEGER,
    style_id INTEGER,
    owner_id INTEGER,
    ispublic,
    isactive,
    tags
  ) ;

CREATE INDEX IF NOT EXISTS kmedia_own ON media ( owner_id, style_id, media_id ) ;

CREATE TABLE IF NOT EXISTS
  item
  (
    id INTEGER PRIMARY KEY,
    media_id INTEGER,
    sizes_id INTEGER,
    style_fk INTEGER,
    owner_fk INTEGER,
    `count` INTEGER,
    tags
  ) ;

CREATE UNIQUE INDEX IF NOT EXISTS kitem ON item ( owner_fk, media_id, sizes_id ) ;
CREATE INDEX IF NOT EXISTS kitem_sty ON item ( owner_fk, style_fk, sizes_id ) ;

CREATE TABLE IF NOT EXISTS
  web
  (
    id INTEGER PRIMARY KEY,
    name,
    geom,
    path,
    item_id INTEGER,
    layout,
    dtcreated
  ) ;

CREATE UNIQUE INDEX IF NOT EXISTS kweb_media ON web ( item_id ) ;

CREATE TABLE IF NOT EXISTS
  campaign
  (
    owner_fk INTEGER,
    name,
    tags,
    styles,
    art_prefix,
    isactive
  ) ;

CREATE UNIQUE INDEX IF NOT EXISTS kcampaign ON campaign ( owner_fk, name ) ;

