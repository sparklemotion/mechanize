require 'rubygems'
require 'hoe'

Hoe.plugin :git
Hoe.plugin :minitest

hoe = Hoe.spec 'mechanize' do
  developer 'Eric Hodel',      'drbrain@segment7.net'
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'Mike Dalessio',   'mike.dalessio@gmail.com'
  developer 'Akinori MUSHA',   'knu@idaemons.org'

  self.readme_file      = 'README.rdoc'
  self.history_file     = 'CHANGELOG.rdoc'
  self.extra_rdoc_files += Dir['*.rdoc']

  rdoc_locations << 'drbrain@rubyforge.org:/var/www/gforge-projects/mechanize/'

  self.extra_deps << ['net-http-digest_auth', '~> 1.1', '>= 1.1.1']
  self.extra_deps << ['net-http-persistent',  '~> 2.4', '>= 2.4.1']
  self.extra_deps << ['nokogiri',             '~> 1.4']
  self.extra_deps << ['ruby-ntlm',            '~> 0.1', '>= 0.1.1']
  self.extra_deps << ['webrobots',            '~> 0.0', '>= 0.0.9']
  self.extra_deps << ['domain_name',          '~> 0.5', '>= 0.5.1']

  self.spec_extras[:required_ruby_version] = '>= 1.8.7'
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

desc 'Install deps for travis to work around Hoe/RubyGems bug'
task 'travis_deps' do
  hoe.spec.dependencies.each do |dep|
    first_requirement = dep.requirement.requirements.first.join ' '
    system('gem', 'install', dep.name, '-v', first_requirement,
           '--no-rdoc', '--no-ri')
  end
end

