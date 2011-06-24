require 'rubygems'
require 'mechanize'

agent = Mechanize.new
stack = agent.get(ARGV[0]).links

while l = stack.pop
  next unless l.uri
  host = l.uri.host
  next unless host.nil? or host == agent.history.first.uri.host
  next if agent.visited? l.href

  puts "crawling #{l.uri}"
  begin
    page = l.click
    next unless Mechanize::Page === page
    stack.push(*page.links)
  rescue Mechanize::ResponseCodeError
  end
end

