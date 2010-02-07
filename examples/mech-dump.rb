$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'mechanize'

agent = Mechanize.new
puts agent.get(ARGV[0]).inspect
