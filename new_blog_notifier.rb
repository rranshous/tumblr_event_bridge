require 'streamworker'

name 'new-blog-notifier'
handle 'tumblr' => 'observed-blog' do |state, event, redis|
  blog_href = event[:body]['href']
  if redis.sismember('seen', blog_href)
    puts "SEEN, skipping: #{blog_href}"
    next
  end
  puts "NEW: #{blog_href}"
  blog_data = { href: blog_href, post: event[:body]['post'] }
  emit 'new-images', 'tumblr-image', blog_data
  redis.sadd('seen', blog_href)
end


