# Roda is a simple Rack-based framework with a flexible architecture based
# on the concept of a routing tree. Bridgetown uses it for its development
# server, but you can also run it in production for fast, dynamic applications.
#
# Learn more at: http://roda.jeremyevans.net

class RodaApp < Roda
  plugin :bridgetown_server
  plugin :hooks

  # Add additional Roda configuration here if needed

  # Uncomment to use Bridgetown SSR:
  # plugin :bridgetown_ssr

  # Uncomment to use file-based dynamic routing in your project (make sure you
  # uncomment the gem dependency in your `Gemfile` as well):
  # plugin :bridgetown_routes

  after do |res|
    next unless res

    headers = res[1]
    content_type = headers["Content-Type"]

    next unless content_type
    next if content_type.include?("charset=")

    textual =
      content_type.start_with?("text/") ||
      content_type.start_with?("application/json") ||
      content_type.start_with?("application/javascript") ||
      content_type.start_with?("application/xml") ||
      content_type.start_with?("application/rss+xml") ||
      content_type.start_with?("application/atom+xml") ||
      content_type.start_with?("image/svg+xml")

    headers["Content-Type"] = "#{content_type}; charset=utf-8" if textual
  end

  route do |r|
    # Load Roda routes in server/routes (and src/_routes via `bridgetown-routes`)
    r.bridgetown
  end
end
