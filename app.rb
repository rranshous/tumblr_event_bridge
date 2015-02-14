# GOAL:
# Poll a set of tumblr feeds for changes
# push events into eventstore

require 'feedjira'
require 'eventstore'


blog_urls = %w(http://boobsinmotion.tumblr.com http://puppies.tumblr.com)
urls = blog_urls.map{|url| "#{url}/rss"}
CONNSTRING = 'http://0.0.0.0:2113'
store = EventStore::Client.new(CONNSTRING)
feeds = Feedjira::Feed.fetch_and_parse(urls)

TARGET_STREAM = 'tumblr'

feeds.keys.each do |url|
  feed = feeds[url]
  blog_data = {
    'href' => feed.url,
    'timestamp' => feed.last_modified.iso8601
  }
  store.write_event(TARGET_STREAM, 'observed-blog', blog_data)
  feed.entries.each do |entry|
    post_data = {
      'href' => entry.url,
      'blog' => { 'href' => feed.url },
      'timestamp' => entry.published.iso8601
    }
    store.write_event(TARGET_STREAM, 'observed-post', post_data)
  end
end
