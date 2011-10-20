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

    # ensure the path does not end in /
    path = uri.path.empty? ? 'index.html' : uri.path
    path += 'index.html' if path.end_with? '/'

    path = File.join uri.host, path
    path = path.gsub %r%//+%, '/' # make the path pretty
    @filename = [path, uri.query].compact.join '?'

    FileUtils.mkdir_p File.dirname @filename
    save_as @filename
  end

end

