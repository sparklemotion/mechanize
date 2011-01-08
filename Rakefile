require 'rubygems'
require 'hoe'
Hoe.plugin :bundler
Hoe.plugin :gemspec

Hoe.spec 'mechanize' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Mike Dalessio',   'mike.dalessio@gmail.com'

  self.readme_file      = 'README.rdoc'
  self.history_file     = 'CHANGELOG.rdoc'
  self.extra_rdoc_files += Dir['*.rdoc']
  self.extra_deps       << ['nokogiri', '>= 1.2.1']
  self.extra_deps       << ['net-http-persistent', '~> 1.1']
  self.extra_deps       << ['webrobots', '>= 0.0.5']
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
