# Feedbase

Better Instructions forthcoming

1. Create a PostgreSQL database called feeds.

2. Load database script db/create.sql.

3. API

    Feedbase::Feed[feed_url: feed_url] || Feedbase::Feed.create(feed_url: feed_url)

    # Instance methods and attributes

    Feedbase::Feed#refresh

    Feedbase::Feed#title
    Feedbase::Feed#feed_url
    Feedbase::Feed#items



