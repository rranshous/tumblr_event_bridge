# GOAL:
# Poll a set of tumblr feeds for changes
# push events into eventstore

require 'feedjira'
require 'eventstore'
require 'httparty'

$stdout.sync = true
puts "STARTING POLL TUMBLR"

CONNSTRING = ARGV.shift || 'http://0.0.0.0:2113'
URLS_FILE_URL = ENV['URLS_FILE_URL']

store = EventStore::Client.new(CONNSTRING)

SLEEP_TIME = 60 * 10 # 10 mins
TARGET_STREAM = 'tumblr'

begin
  loop do
    url_lines = HTTParty.get(URLS_FILE_URL).parsed_response.split("\n")
    blog_urls = url_lines.select{|l| !l.start_with?('#') && l.chomp.length>0}
    urls = blog_urls.map{|url| "#{url}/rss"}
    feeds = Feedjira::Feed.fetch_and_parse(urls)
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
          'timestamp' => nil
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
    puts "SLEEPING #{SLEEP_TIME}"
    sleep SLEEP_TIME
  end
rescue => ex
  puts "EXCEPTION: #{ex}"
  raise
end
