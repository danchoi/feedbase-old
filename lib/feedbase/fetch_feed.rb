require 'feedbase/feed_parser'
require 'timeout'
require 'iconv'

module Feedbase
  class FetchFeed

    attr_accessor :feed_url

    def initialize(feed_url)
      @feed_url = feed_url
    end

    def headers
      if @headers
        return @headers 
      end
      _headers = begin
                   Timeout::timeout(20) do
                     agent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3"
                     # get headers and any redirects
                     res = `curl -sIL -A'#{agent}' '#{feed_url}'`.gsub("\r\n", "\n")
                     if res !~ /^HTTP.*200 OK$/
                       puts res.inspect
                       raise "Response not OK"
                     end
                     res
                   end 
                 end

      #TODO check for xml 
      @headers = { headers: _headers, 
        encoding: _headers[/^Content-Type:.*charset=(.*)$/i, 1],
        etag: _headers[/^ETag: (.*)$/,1],
        last_modified: ((x = _headers[/Last-Modified: (.*)/, 1]) && DateTime.parse(x)) }
    end

    def fetch
      url = fix_url(feed_url)
      start_time = Time.now
      result = begin
                 Timeout::timeout(20) do
                   agent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3" 
                   headers
                   # get headers and any redirects
                   `curl -sL -A'#{agent}' '#{url}'`
                   end
                 rescue StandardError, Timeout::Error => ex
                   raise
                 end
      elapsed = Time.now - start_time
      if !(x = headers[:headers].scan(/^Location: (.*)$/).flatten).empty?
        #puts "Redirected to #{x.last}"
        feed_url = x.last
      end
      result2 = Iconv.conv("UTF-8//TRANSLIT//IGNORE", (headers[:encoding] || 'iso-8859-1'), result)
      f = FeedParser.new(result2).result
      feed_params = {:feed_url => feed_url, :title => f[:title], :web_url => f[:link]}
      items = f[:items]

      { feed_params: feed_params,
        items: f[:items],
        download_params: headers.merge(download_time: elapsed) }
    end

    def fix_url(url)
      unless url =~ /^https?:\/\//
        url = "http://" + url
      end
      url
    end
  end

end


if __FILE__ == $0
  puts Feedbase::FetchFeed.new(ARGV.first).fetch
end


