$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new
puts agent.get(ARGV[0]).inspect
