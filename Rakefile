require 'rubygems'
require 'hoe'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require 'mechanize'

HOE = Hoe.new('mechanize', WWW::Mechanize::VERSION) do |p|
  p.developer('Aaron Patterson','aaronp@rubyforge.org')
  p.developer('Mike Dalessio','mike.dalessio@gmail.com')
  p.readme_file     = 'README.rdoc'
  p.history_file    = 'CHANGELOG.rdoc'
  p.extra_rdoc_files  = FileList['*.rdoc']
  p.summary         = "Mechanize provides automated web-browsing"
  p.extra_deps      = [['nokogiri', '>= 1.2.1']]
end

desc "Update SSL Certificate"
task('ssl_cert') do |p|
  sh "openssl genrsa -des3 -out server.key 1024"
  sh "openssl req -new -key server.key -out server.csr"
  sh "cp server.key server.key.org"
  sh "openssl rsa -in server.key.org -out server.key"
  sh "openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt"
  sh "cp server.key server.pem"
  sh "mv server.key server.csr server.crt server.pem test/data/"
  sh "rm server.key.org"
end

namespace :gem do
  desc 'Generate a gem spec'
  task :spec do
    File.open("#{HOE.name}.gemspec", 'w') do |f|
      HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
      f.write(HOE.spec.to_ruby)
    end
  end
end

desc "Run code-coverage analysis"
task :coverage do
  rm_rf "coverage"
  sh "rcov -x Library -I lib:test #{Dir[*HOE.test_globs].join(' ')}"
end
