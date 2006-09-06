require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/sshpublisher'

def announce(msg='')
  STDERR.puts msg
end

PKG_BUILD = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME = 'mechanize'
PKG_VERSION = '0.6.0' + PKG_BUILD
PKG_FILES = FileList["{doc,lib,test}/**/*"].exclude("rdoc").to_a

spec = Gem::Specification.new do |s|
  s.name      = PKG_NAME
  s.version   = PKG_VERSION
  s.author    = "Aaron Patterson"
  s.email     = "aaronp@rubyforge.org"
  s.homepage  = "#{PKG_NAME}.rubyforge.org"
  s.platform  = Gem::Platform::RUBY
  s.summary   = "Mechanize provides automated web-browsing"
  s.files     = Dir.glob("{bin,test,lib,doc}/**/*").delete_if {|item| item.include?(".svn") }
  s.require_path  = "lib"
  s.has_rdoc      = true
  s.extra_rdoc_files = ["README", "EXAMPLES", "CHANGELOG", "LICENSE", "NOTES",
                        "GUIDE"]
  s.rdoc_options << "--main" << 'README' << "--title" << "'WWW::Mechanize RDoc'"
  s.rubyforge_project = PKG_NAME
  s.add_dependency('hpricot') 
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |p|
  p.main = "README"
  p.rdoc_dir = "doc"
  p.rdoc_files.include("README", "CHANGELOG", "LICENSE", "EXAMPLES", "NOTES",
                       "GUIDE", "lib/**/*.rb")
  p.options << "--main" << 'README' << "--title" << "WWW::Mechanize RDoc"
end

desc "Publish the API documentation"
task :pubrdoc => [ :rdoc ] do
  Rake::SshDirPublisher.new(
    "#{ENV['USER']}@rubyforge.org",
    "/var/www/gforge-projects/#{PKG_NAME}/",
    "doc" ).upload
end

task :update_version do
  announce "Updating Mechanize Version to #{PKG_VERSION}"
  File.open("lib/mechanize/mech_version.rb", "w") do |f|
    f.puts "module WWW"
    f.puts "  class Mechanize"
    f.puts "    Version = '#{PKG_VERSION}'"
    f.puts "  end"
    f.puts "end"
  end
  sh 'svn commit -m"updating version" lib/mechanize/mech_version.rb'
end

desc "Create a new release"
task :release => [ :clobber, :update_version, :package, :tag ] do
  announce 
  announce "**************************************************************"
  announce "* Release #{PKG_VERSION} Complete."
  announce "* Packages ready to upload."
  announce "**************************************************************"
  announce 
end

desc "Tag code"
Rake::Task.define_task("tag") do |p|
  baseurl = "svn+ssh://#{ENV['USER']}@rubyforge.org//var/svn/#{PKG_NAME}"
  sh "svn cp -m 'tagged #{ PKG_VERSION }' . #{ baseurl }/tags/REL-#{ PKG_VERSION }"
end

desc "Branch code"
Rake::Task.define_task("branch") do |p|
  baseurl = "svn+ssh://#{ENV['USER']}@rubyforge.org/var/svn/#{PKG_NAME}"
  sh "svn cp -m 'branched #{ PKG_VERSION }' #{baseurl}/trunk #{ baseurl }/branches/RB-#{ PKG_VERSION }"
end

desc "Update SSL Certificate"
Rake::Task.define_task('ssl_cert') do |p|
  sh "openssl genrsa -des3 -out server.key 1024"
  sh "openssl req -new -key server.key -out server.csr"
  sh "cp server.key server.key.org"
  sh "openssl rsa -in server.key.org -out server.key"
  sh "openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt"
  sh "cp server.key server.pem"
  sh "mv server.key server.csr server.crt server.pem test/data/"
  sh "rm server.key.org"
end
