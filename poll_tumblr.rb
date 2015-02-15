# GOAL:
# Poll a set of tumblr feeds for changes
# push events into eventstore

require 'feedjira'
require 'eventstore'


blog_urls = File.readlines('urls.txt').map(&:chomp)
urls = blog_urls.map{|url| "#{url}/rss"}
CONNSTRING = 'http://0.0.0.0:2113'
store = EventStore::Client.new(CONNSTRING)
feeds = Feedjira::Feed.fetch_and_parse(urls)

TARGET_STREAM = 'tumblr'

feeds.keys.each do |url|
  puts "BLOG: #{url}"
  feed = feeds[url]
  if feed.is_a?(Fixnum)
    puts "BAD FEED: #{feed}"
    next
  end
  begin
    blog_data = {
      'href' => feed.url,
      'timesetamp' => nil
    }
    if feed.last_modified
      blog_data.merge!({ 'timestamp' => feed.last_modified.iso8601 })
    end
    store.write_event(TARGET_STREAM, 'observed-blog', blog_data)
  rescue => ex
    puts "ERROR: #{ex}"
  end
  feed.entries.each do |entry|
    begin
      post_data = {
        'href' => entry.url,
        'blog' => { 'href' => feed.url },
        'timestamp' => entry.published.iso8601
      }
      store.write_event(TARGET_STREAM, 'observed-post', post_data)
    rescue => ex
      puts "ERROR: #{ex}"
    end
  end
end
