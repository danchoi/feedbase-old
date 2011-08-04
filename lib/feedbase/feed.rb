require 'sequel'
require 'feedbase/fetch_feed'
unless defined?(DB)
  DB = Sequel.connect 'postgres:///feeds'
end

module Feedbase

  class Redirected < StandardError; end

  class Feed < Sequel::Model
    one_to_many :items
    one_to_many :feed_downloads

    # returns number of items created
    def refresh(force=false)
      # check headers and etag and last modified
      raise "Missing feed_url" if feed_url.nil?
      ff = Feedbase::FetchFeed.new(feed_url)
      headers = ff.headers
      if !force 
        if last_etag && (headers[:etag] == last_etag)
          puts "-- #{feed_url} -- ETag cache hit"
          return
        end
      end
      data = ff.fetch 
      params = data[:feed_params].merge(:alpha_title => make_alpha_title(data[:feed_params][:title])) 
      if params[:feed_url] != self[:feed_url]
        if x = self.class.filter(:feed_url => params[:feed_url]).first
          raise Redirected.new("Redirected to existing feed: #{x.feed_url}")
        end
      end
      params.delete(:feed_url) 
      begin Sequel::DatabaseError
        update params
      rescue StandardError # PGError
        puts "The offending record is #{self.inspect}"
        raise
      end

      Feedbase::FeedDownload.create({feed_id: feed_id}.merge(data[:download_params])) 
      items_created = data[:items].
        select {|item| Feedbase::Item[:guid => item[:guid]].nil?}.
        map { |item|
          params = {
            feed_id: feed_id,
            title: item[:title].encode("utf-8"), 
            guid: item[:guid], 
            link: item[:link],
            content: item[:content],
            author: item[:author],
            word_count: item[:word_count],
            pub_date: item[:pub_date]
          }
          Feedbase::Item.create params
        }
      # caller can extract an item count from this
      items_created
    end

    def last_download
      @last_download ||= FeedDownload.filter(feed_id: feed_id).first
    end

    def last_etag
      last_download && last_download.etag
    end

    def last_modified
      last_download && last_download.last_modified
    end

    def make_alpha_title(s)
      return if s.nil?
      s.gsub(/^(The|A|An)\s/, '')
    end
  end

  class Item < Sequel::Model
    many_to_one :feed
  end

  class FeedDownload < Sequel::Model
  end

end

if __FILE__ == $0
  feed = Feedbase::Feed[feed_url: ARGV.first] || Feedbase::Feed.create(feed_url: ARGV.first)
  puts feed
  puts feed.refresh
end

