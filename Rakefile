require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'

PKG_BUILD = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME = 'daapclient'
PKG_VERSION = '1.0.0' + PKG_BUILD
PKG_FILES = FileList["{doc,lib,test}/**/*"].exclude("rdoc").to_a

MECH_VERSION = "0.4.1"

spec = Gem::Specification.new do |s|
  s.name      = "mechanize"
  s.version   = MECH_VERSION
  s.author    = "Aaron Patterson"
  s.email     = "aaronp@rubyforge.org"
  s.homepage  = "mechanize.rubyforge.org"
  s.platform  = Gem::Platform::RUBY
  s.summary   = "Mechanize provides automated web-browsing"
  s.files     = Dir.glob("{bin,test,lib,doc}/**/*").delete_if {|item| item.include?(".svn") }
  s.require_path  = "lib"
  s.autorequire   = "mechanize"
  s.has_rdoc      = true
  s.extra_rdoc_files = ["README", "EXAMPLES", "CHANGELOG", "LICENSE"]
  s.rdoc_options << "--main" << 'README'
  s.rubyforge_project = "mechanize"
  s.add_dependency('ruby-web', '>= 1.1.0') 
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |p|
  p.main = "README"
  p.rdoc_dir = "doc"
  p.rdoc_files.include("README", "CHANGELOG", "LICENSE", "EXAMPLES", "lib/**/*.rb")
end

Rake::Task.define_task("tag") do |p|
  baseurl = "svn+ssh://#{ENV['USER']}@rubyforge.org//var/svn/mechanize"
  sh "svn cp -m 'tagged #{ MECH_VERSION }' #{ baseurl }/trunk #{ baseurl }/tags/REL-#{ MECH_VERSION }"
end

