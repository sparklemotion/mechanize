$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new
agent.set_proxy('localhost', '8000')
page = agent.get(ARGV[0])
puts page.body
