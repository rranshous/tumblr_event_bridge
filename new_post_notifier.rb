require 'streamworker'

name 'new-post-notifier'
handle 'tumblr' => 'observed-post' do |state, event, redis|
  post_href = event[:body]['href']
  if redis.sismember('seen', post_href)
    puts "SEEN, skipping: #{post_href}"
    next
  end
  puts "NEW: #{post_href}"
  post_data = { href: post_href,
                blog: event[:body]['blog'],
                timestamp: event[:body]['timestamp'] }
  emit 'new-posts', 'tumblr-post', post_data
  redis.sadd('seen', post_href)
end
