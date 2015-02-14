require 'eventstore'
require 'httparty'

CONNSTRING = 'http://0.0.0.0:2113'
store = EventStore::Client.new(CONNSTRING)
read_until = ARGV.shift || 10

puts "READING UNTIL #{read_until}"
events = store.read_events('new-posts', read_until)
events.each do |event|
  post_href = event[:body]["href"]
  response = HTTParty.get("#{post_href}/xml",
                          headers: {'Accept'=>'application/xml'})
  post_data = response.parsed_response
  next unless post_data.is_a?(Hash)
  puts "ID: #{last_id}"
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
end
