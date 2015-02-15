require 'eventstore'
require 'httparty'

CONNSTRING = ARGV.shift || 'http://0.0.0.0:2113'
start_at = ARGV.shift || 0

$stdout.sync = true
puts "STARTING POST IMAGE NOTIFIER"

store = EventStore::Client.new(CONNSTRING)
SLEEP_TIME = 10
last_start_at = nil

begin
  loop do
    if last_start_at == start_at
      puts "SLEEPING: #{SLEEP_TIME}"
      sleep SLEEP_TIME
    end
    last_start_at = start_at
    puts "RESUMING: #{start_at}"
    events = store.resume_read('new-posts', start_at, 100)
    events.each do |event|
      post_href = event[:body]["href"]
      response = HTTParty.get("#{post_href}/xml",
                              headers: {'Accept'=>'application/xml'})
      post_data = response.parsed_response
      next unless post_data.is_a?(Hash)
      puts "ID: #{event[:id]}"
      post_type = post_data["tumblr"]["posts"]["post"]["type"]
      if post_type == "photo"
        image_versions = Hash[
          post_data["tumblr"]["posts"]["post"]["photo_url"]
          .map{|d| [d["max_width"].to_i, d["__content__"]] }
        ]
        image_versions.each do |width, url|
          image_data = {
            href: url,
            width: width,
            post: { href: post_href }
          }
          store.write_event('post-images', 'tumblr-image', image_data)
        end
      else
        puts "NOTPHOTO"
      end
      start_at = event[:id]
    end
    puts "RESTARTAT: #{start_at}"
  end
rescue => ex
  puts "EXCEPTION: #{ex}"
  raise
end
