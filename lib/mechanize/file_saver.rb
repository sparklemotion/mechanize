##
# This is a pluggable parser that automatically saves every file it
# encounters.  It saves the files as a tree, reflecting the host and file
# path.
#
# == Example
#
# This example saves all .pdf files
#
#   require 'mechanize'
#
#   agent = Mechanize.new
#   agent.pluggable_parser.pdf = Mechanize::FileSaver
#   agent.get('http://example.com/foo.pdf')
#
#   Dir['example.com/*'] # => foo.pdf

class Mechanize::FileSaver < Mechanize::File

  attr_reader :filename

  def initialize uri = nil, response = nil, body = nil, code = nil
    super

    path = uri.path.empty? ? 'index.html' : uri.path.gsub(/^[\/]*/, '')
    path += 'index.html' if path =~ /\/$/

    split_path = path.split(/\//)
    filename = split_path.length > 0 ? split_path.pop : 'index.html'

    joined_path = File.join split_path

    path = if joined_path.empty? then
             uri.host
           else
             File.join uri.host, joined_path
           end

    @filename = File.join path, filename
    FileUtils.mkdir_p path
    save_as @filename
  end

end

