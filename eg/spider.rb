$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new
stack = agent.get(ARGV[0]).links
while l = stack.pop
  next unless l.uri.host == agent.history.first.uri.host
  stack.push(*(agent.click(l).links)) unless agent.visited? l.href
end
