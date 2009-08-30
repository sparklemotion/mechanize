require 'rubygems'
require 'hoe'

Hoe.spec 'mechanize' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Mike Dalessio',   'mike.dalessio@gmail.com'

  self.readme_file      = 'README.rdoc'
  self.history_file     = 'CHANGELOG.rdoc'
  self.extra_rdoc_files += Dir['*.rdoc']
  self.extra_deps       << ['nokogiri', '>= 1.2.1']
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

desc 'Generate a gem spec'
task "gem:spec" do
  File.open("mechanize.gemspec", 'w') do |f|
    now = Time.now.strftime("%Y%m%d%H%M%S")
    f.write `rake debug_gem`.sub(/(s.version = ".*)(")/) { "#{$1}.#{now}#{$2}" }
  end
end

