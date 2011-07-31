-- this is for postgresql
drop table if exists feeds CASCADE;
drop table if exists feed_downloads CASCADE;
drop table if exists items CASCADE;

create table feeds (
  feed_id serial primary key,
  feed_url varchar UNIQUE NOT NULL,
  title varchar,
  alpha_title varchar,
  subtitle varchar,
  web_url varchar,
  favicon_url varchar,
  subscribers integer default 0,
  created timestamp default now()
);

create table feed_downloads (
  feed_download_id serial primary key,
  feed_id integer REFERENCES feeds (feed_id) ON DELETE CASCADE,
  download_time float,
  headers text,
  encoding varchar,
  etag varchar,
  last_modified timestamp,
  created timestamp default now()
);

create table items (
  item_id serial primary key,
  feed_id integer REFERENCES feeds (feed_id) ON DELETE CASCADE,
  guid varchar UNIQUE NOT NULL,
  title varchar,
  link varchar,
  content text,
  author varchar,
  word_count integer,
  pub_date timestamp default now()
);

