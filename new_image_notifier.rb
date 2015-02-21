require 'streamworker'

name 'new-image-notifier'
handle 'post-images' => 'tumblr-image' do |state, event, redis|
  image_href = event[:body]['href']
  if redis.sismember('seen', image_href)
    puts "SEEN, skipping: #{image_href}"
    next
  end
  puts "NEW: #{image_href}"
  image_data = { href: image_href, post: event[:body]['post'] }
  emit 'new-images', 'tumblr-image', image_data
  redis.sadd('seen', image_href)
end

