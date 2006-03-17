require 'rubygems'

if File.read('lib/mechanize.rb') =~ /Version\s+=\s+"(\d+\.\d+\.\d+)"/
  version = $1 
else
  raise "no version"
end

spec = Gem::Specification.new do |s|
  s.name = 'mechanize'
  s.version = version 
  s.summary = 'Automated web-browsing.'
  s.add_dependency('narf', '>= 0.6.3') 

  s.files = Dir['**/*'].delete_if {|item| item.include?(".svn") }

  s.require_path = 'lib'

  s.author = "Michael Neumann"
  s.email = "mneumann@ntecs.de"
  s.homepage = "rubyforge.org/projects/wee"
end
