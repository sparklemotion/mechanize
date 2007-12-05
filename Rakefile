require 'rubygems'
require 'hoe'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require 'mechanize'

class MechHoe < Hoe
  def define_tasks
    super

    desc "Tag code"
    task :tag do |p|
      abort "Must supply VERSION=x.y.z" unless ENV['VERSION']
      v = ENV['VERSION'].gsub(/\./, '_')

      rf = RubyForge.new
      user = rf.userconfig['username']

      baseurl = "svn+ssh://#{user}@rubyforge.org//var/svn/#{name}"
      sh "svn cp -m 'tagged REL-#{v}' . #{ baseurl }/tags/REL-#{ v }"
    end

    desc "Branch code"
    Rake::Task.define_task("branch") do |p|
      abort "Must supply VERSION=x.y.z" unless ENV['VERSION']
      v = ENV['VERSION'].split(/\./)[0..1].join('_')

      rf = RubyForge.new
      user = rf.userconfig['username']

      baseurl = "svn+ssh://#{user}@rubyforge.org/var/svn/#{name}"
      sh "svn cp -m'branched #{v}' #{baseurl}/trunk #{baseurl}/branches/RB-#{v}"
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
  end
end

MechHoe.new('mechanize', WWW::Mechanize::VERSION) do |p|
  p.rubyforge_name  = 'mechanize'
  p.author          = 'Aaron Patterson'
  p.email           = 'aaronp@rubyforge.org'
  p.summary         = "Mechanize provides automated web-browsing"
  p.description     = p.paragraphs_of('README.txt', 3).join("\n\n")
  p.url             = p.paragraphs_of('README.txt', 1).first.strip
  p.changes         = p.paragraphs_of('CHANGELOG.txt', 0..2).join("\n\n")
  p.extra_deps      = [['hpricot', '>= 0.5.0']]
end


