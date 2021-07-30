# coding: utf-8
# frozen_string_literal: true
require_relative 'lib/mechanize/version'

Gem::Specification.new do |spec|
  spec.name = "mechanize"
  spec.version = Mechanize::VERSION
  spec.homepage = "https://github.com/sparklemotion/mechanize"
  spec.summary = 'The Mechanize library is used for automating interaction with websites'
  spec.description =
    [
      "The Mechanize library is used for automating interaction with websites.",
      "Mechanize automatically stores and sends cookies, follows redirects,",
      "and can follow links and submit forms.  Form fields can be populated and",
      "submitted.  Mechanize also keeps track of the sites that you have visited as",
      "a history.",
    ].join("\n")

  spec.authors =
    [
      'Eric Hodel',
      'Aaron Patterson',
      'Mike Dalessio',
      'Akinori MUSHA',
      'Lee Jarvis',
    ]
  spec.email =
    [
      'drbrain@segment7.net',
      'aaron.patterson@gmail.com',
      'mike.dalessio@gmail.com',
      'knu@idaemons.org',
      'ljjarvis@gmail.com',
    ]

  spec.metadata = {
    'yard.run'          => 'yard',
    'bug_tracker_uri'   => 'https://github.com/sparklemotion/mechanize/issues',
    'changelog_uri'     => 'https://github.com/sparklemotion/mechanize/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://www.rubydoc.info/gems/mechanize',
    'homepage_uri'      => 'https://github.com/sparklemotion/mechanize',
    'source_code_uri'   => 'https://github.com/sparklemotion/mechanize'
  }

  spec.license = "MIT"

  spec.require_paths = ["lib"]
  spec.files = %x(git ls-files).split($/)
  spec.test_files = spec.files.grep(%r{^test/})

  spec.extra_rdoc_files += Dir['*.rdoc', '*.md']
  spec.rdoc_options = ["--main", "README.md"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_runtime_dependency("addressable", "~> 2.8")
  spec.add_runtime_dependency("domain_name", ">= 0.5.20190701", "~> 0.5")
  spec.add_runtime_dependency("http-cookie", ">= 1.0.3", "~> 1.0")
  spec.add_runtime_dependency("mime-types", "~> 3.0")
  spec.add_runtime_dependency("net-http-digest_auth", ">= 1.4.1", "~> 1.4")

  # careful! some folks are relying on older versions of net-http-persistent
  # - see the socks proxy patch in use at #507 and #464
  # - see use of retry_change_requests that was removed at #558
  spec.add_runtime_dependency("net-http-persistent", ">= 2.5.2", "< 5.0.dev")

  spec.add_runtime_dependency("nokogiri", ">= 1.11.2", "~> 1.11")
  spec.add_runtime_dependency("rubyntlm", ">= 0.6.3", "~> 0.6")
  spec.add_runtime_dependency("webrick", "~> 1.7")
  spec.add_runtime_dependency("webrobots", "~> 0.1.2")

  spec.add_development_dependency("minitest", "~> 5.14")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rdoc", "~> 6.3")
  spec.add_development_dependency("rubocop", "~> 1.12")
end
