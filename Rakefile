require 'rubygems'
require "bundler/gem_tasks"

require 'rdoc/task'

task :prerelease => [:clobber_rdoc, :check_manifest, :test]

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

desc "Run tests"
task "test" do
  ruby "-I'lib:test' " + FileList['test/**/test*.rb'].join(' ')
end
