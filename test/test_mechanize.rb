# coding: utf-8

require 'helper'

class TestMechanize < MiniTest::Unit::TestCase

  KEY = OpenSSL::PKey::RSA.new 512
  name = OpenSSL::X509::Name.parse 'CN=nobody/DC=example'
  CERT = OpenSSL::X509::Certificate.new
  CERT.version = 2
  CERT.serial = 0
  CERT.not_before = Time.now
  CERT.not_after = Time.now + 60
  CERT.public_key = KEY.public_key
  CERT.subject = name
  CERT.issuer = name
  CERT.sign KEY, OpenSSL::Digest::SHA1.new

  def setup
    @mech = Mechanize.new
    @mech.log = nil
    @uri = URI.parse 'http://example/'
    @req = Net::HTTP::Get.new '/'

    @res = Net::HTTPOK.allocate
    @res.instance_variable_set :@code, 200
    @res.instance_variable_set :@header, {}

    @headers = if RUBY_VERSION > '1.9' then
                 %w[accept user-agent]
               else
                 %w[accept]
               end
  end

  def test_back
    0.upto(5) do |i|
      assert_equal(i, @mech.history.size)
      @mech.get("http://localhost/")
    end
    @mech.get("http://localhost/form_test.html")

    assert_equal("http://localhost/form_test.html",
      @mech.history.last.uri.to_s)
    assert_equal("http://localhost/",
      @mech.history[-2].uri.to_s)

    assert_equal(7, @mech.history.size)
    @mech.back
    assert_equal(6, @mech.history.size)
    assert_equal("http://localhost/",
      @mech.history.last.uri.to_s)
  end

  def test_basic_auth
    @mech.basic_auth('user', 'pass')
    page = @mech.get("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
  end

  def test_cert_key_file
    Tempfile.open 'key' do |key|
      Tempfile.open 'cert' do |cert|
        key.write KEY.to_pem
        key.rewind

        cert.write CERT.to_pem
        cert.rewind

        mech = Mechanize.new do |a|
          a.cert = cert.path
          a.key  = key.path
        end

        # Certificate#== seems broken
        assert_equal CERT.to_pem, mech.certificate.to_pem
      end
    end
  end

  def test_cert_key_object
    mech = Mechanize.new do |a|
      a.cert = CERT
      a.key  = KEY
    end

    assert_equal CERT, mech.certificate
  end

  def test_click
    @mech.user_agent_alias = 'Mac Safari'
    page = @mech.get("http://localhost/frame_test.html")
    link = page.link_with(:text => "Form Test")

    page = @mech.click(link)

    assert_equal("http://localhost/form_test.html",
                 @mech.history.last.uri.to_s)
  end

  def test_click_frame_hpricot_style
    page = @mech.get("http://localhost/frame_test.html")
    link = (page/"//frame[@name='frame2']").first

    page = @mech.click(link)

    assert_equal("http://localhost/form_test.html",
                 @mech.history.last.uri.to_s)
  end

  def test_click_hpricot_style # HACK move to test_divide in Page
    page = @mech.get("http://localhost/frame_test.html")
    link = (page/"//a[@class='bar']").first

    page = @mech.click(link)

    assert_equal("http://localhost/form_test.html",
                 @mech.history.last.uri.to_s)
  end

  def test_click_link
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    page = agent.get("http://localhost/frame_test.html")
    link = page.link_with(:text => "Form Test")

    agent.click link

    assert_equal("http://localhost/form_test.html",
      agent.history.last.uri.to_s)
  end

  def test_click_link_hpricot_style # HACK move to test_search in Page
    page = @mech.get("http://localhost/tc_encoded_links.html")

    page = @mech.click(page.search('a').first)

    assert_equal("http://localhost/form_post?a=b&b=c", page.uri.to_s)
  end

  def test_click_link_query
    page = @mech.get("http://localhost/tc_encoded_links.html")
    link = page.links.first
    assert_equal('/form_post?a=b&b=c', link.href)

    page = @mech.click(link)

    assert_equal("http://localhost/form_post?a=b&b=c", page.uri.to_s)
  end

  def test_click_link_space
    page = @mech.get("http://localhost/tc_bad_links.html")

    @mech.click page.links.first

    assert_match(/alt_text.html$/, @mech.history.last.uri.to_s)
    assert_equal(2, @mech.history.length)
  end

  def test_click_more
    @mech.get 'http://localhost/test_click.html'
    @mech.click 'A Button'
    assert_equal 'http://localhost/frame_test.html?words=nil',
      @mech.page.uri.to_s
    @mech.back
    @mech.click 'A Link'
    assert_equal 'http://localhost/index.html',
      @mech.page.uri.to_s
    @mech.back
    @mech.click @mech.page.link_with(:text => 'A Link')
    assert_equal 'http://localhost/index.html',
      @mech.page.uri.to_s
  end

  def test_cookie_jar
    assert_kind_of Mechanize::CookieJar, @mech.cookie_jar

    jar = Mechanize::CookieJar.new

    @mech.cookie_jar = jar

    assert_equal jar, @mech.cookie_jar
  end

  def test_delete
    page = @mech.delete('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 1, @mech.history.length
    assert_equal 'DELETE', page.header['X-Request-Method']
  end

  def test_delete_redirect
    page = @mech.delete('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  #def test_download
  #  Dir.mktmpdir do |dir|
  #    file = "#{dir}/download"
  #    open file, 'w' do |io|
  #      @mech.download 'http://example', io
  #    end

  #    assert_equal 1, File.stat(file).size
  #  end
  #end

  def test_get
    page = @mech.get('http://localhost', { :q => 'h' }, 'http://example',
                      { 'X-H' => 'v' })

    assert_equal 'http://localhost/?q=h', page.uri.to_s
  end

  def test_get_HTTP
    page = @mech.get('HTTP://localhost/', { :q => 'hello' })
    assert_equal('HTTP://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_anchor
    page = @mech.get('http://localhost/?foo=bar&#34;')
    assert_equal('http://localhost/?foo=bar%22', page.uri.to_s)
  end

  def test_get_bad_url
    assert_raises ArgumentError do
      @mech.get '/foo.html'
    end
  end

  def test_get_basic_auth_bad
    @mech.basic_auth('aaron', 'aaron')

    e = assert_raises Mechanize::ResponseCodeError do
      @mech.get("http://localhost/basic_auth")
    end

    assert_equal("401", e.response_code)
  end

  def test_get_basic_auth_none
    e = assert_raises Mechanize::ResponseCodeError do
      @mech.get("http://localhost/basic_auth")
    end

    assert_equal("401", e.response_code)
  end

  def test_get_digest_auth
    block_called = false

    @mech.basic_auth('user', 'pass')

    @mech.pre_connect_hooks << lambda { |_, request|
      block_called = true
      request.to_hash.each do |k,v|
        assert_equal(1, v.length)
      end
    }

    page = @mech.get("http://localhost/digest_auth")
    assert_equal('You are authenticated', page.body)
    assert block_called
  end

  def test_get_file
    page = @mech.get("http://localhost/frame_test.html")
    content_length = page.header['Content-Length']
    page_as_string = @mech.get_file("http://localhost/frame_test.html")
    assert_equal(content_length.to_i, page_as_string.length.to_i)
  end

  def test_get_follow_meta_refresh
    @mech.follow_meta_refresh = true

    page = @mech.get('http://localhost/tc_follow_meta.html')

    assert_equal(2, @mech.history.length)

    assert_equal('http://localhost/tc_follow_meta.html',
                 @mech.history.first.uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @mech.history.last.uri.to_s)
  end

  def test_get_follow_meta_refresh_anywhere
    @mech.follow_meta_refresh = :anywhere
    requests = []
    @mech.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @mech.get('http://localhost/tc_meta_in_body.html')
    assert_equal 2, requests.length
  end

  def test_get_follow_meta_refresh_disabled
    page = @mech.get('http://localhost/tc_follow_meta.html')
    assert_equal('http://localhost/tc_follow_meta.html', page.uri.to_s)
    assert_equal(1, page.meta_refresh.length)
  end

  def test_get_follow_meta_refresh_empty_url
    @mech.follow_meta_refresh = true

    page = @mech.get('http://localhost/refresh_with_empty_url')

    assert_equal(3, @mech.history.length)
    assert_equal('http://localhost/refresh_with_empty_url',
                 @mech.history[0].uri.to_s)
    assert_equal('http://localhost/refresh_with_empty_url',
                 @mech.history[1].uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @mech.history.last.uri.to_s)
  end

  def test_get_follow_meta_refresh_in_body
    @mech.follow_meta_refresh = true
    requests = []
    @mech.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @mech.get('http://localhost/tc_meta_in_body.html')
    assert_equal 1, requests.length
  end

  def test_get_follow_meta_refresh_no_url
    @mech.follow_meta_refresh = true

    page = @mech.get('http://localhost/refresh_without_url')

    assert_equal(3, @mech.history.length)
    assert_equal('http://localhost/refresh_without_url',
                 @mech.history[0].uri.to_s)
    assert_equal('http://localhost/refresh_without_url',
                 @mech.history[1].uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @mech.history.last.uri.to_s)
  end

  def test_get_follow_meta_refresh_referer_not_sent
    @mech.follow_meta_refresh = true

    requests = []

    @mech.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @mech.get('http://localhost/tc_follow_meta.html')

    assert_equal 2, @mech.history.length
    assert_nil requests.last['referer']
  end

  def test_get_gzip
    page = @mech.get("http://localhost/gzip?file=index.html")

    assert_kind_of(Mechanize::Page, page)

    assert_match('Hello World', page.body)
  end

  def test_content_encoding_hooks_header
    h = {'X-ResponseContentEncoding' => 'agzip'}

    # test of X-ResponseContentEncoding feature
    assert_raises(Mechanize::Error, 'Unsupported Content-Encoding: agzip') do
      @mech.get("http://localhost/gzip?file=index.html", nil, nil, h)
    end

    @mech.content_encoding_hooks << lambda{|agent, uri, response, response_body_io|
      response['content-encoding'] = 'gzip' if response['content-encoding'] == 'agzip'}

    page = @mech.get("http://localhost/gzip?file=index.html", nil, nil, h)

    assert_match('Hello World', page.body)
  end

  def external_cmd(io); Zlib::GzipReader.new(io).read; end

  def test_content_encoding_hooks_body_io
    h = {'X-ResponseContentEncoding' => 'unsupported_content_encoding'}

   @mech.content_encoding_hooks << lambda{|agent, uri, response, response_body_io|
      if response['content-encoding'] == 'unsupported_content_encoding'
        response['content-encoding'] = 'none'
        response_body_io.string = external_cmd(response_body_io)
      end}

    page = @mech.get("http://localhost/gzip?file=index.html", nil, nil, h)

    assert_match('Hello World', page.body)
  end

  def test_get_http_refresh
    @mech.follow_meta_refresh = true

    requests = []

    @mech.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    page = @mech.get('http://localhost/http_refresh?refresh_time=0')

    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal(2, @mech.history.length)
    assert_nil requests.last['referer']
  end

  def test_get_http_refresh_delay
    @mech.follow_meta_refresh = true
    class << @mech.agent
      attr_accessor :slept
      def sleep *args
        @slept = args
      end
    end

    @mech.get('http://localhost/http_refresh?refresh_time=1')
    assert_equal [1], @mech.agent.slept
  end

  def test_get_http_refresh_disabled
    page = @mech.get('http://localhost/http_refresh?refresh_time=0')
    assert_equal('http://localhost/http_refresh?refresh_time=0', page.uri.to_s)
  end

  def test_get_kcode
    $KCODE = 'u'
    page = @mech.get("http://localhost/?a=#{[0xd6].pack('U')}")

    assert_equal('http://localhost/?a=%D6', page.uri.to_s)

    $KCODE = 'NONE'
  end unless RUBY_VERSION >= '1.9.0'

  def test_get_query
    page = @mech.get('http://localhost/', { :q => 'hello' })
    assert_equal('http://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_redirect
    page = @mech.get('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_get_redirect_found
    page = @mech.get('http://localhost/response_code?code=302&ct=test/xml')

    assert_equal('http://localhost/index.html', page.uri.to_s)

    assert_equal(2, @mech.history.length)
  end

  def test_get_redirect_infinite
    assert_raises(Mechanize::RedirectLimitReachedError) {
      @mech.get('http://localhost/infinite_refresh')
    }
  end

  def test_get_referer
    request = nil
    @mech.pre_connect_hooks << lambda { |_, req|
      request = req
    }

    @mech.get('http://localhost/', [], 'http://tenderlovemaking.com/')
    assert_equal 'http://tenderlovemaking.com/', request['Referer']
  end

  def test_get_referer_file
    uri = URI.parse 'http://tenderlovemaking.com/crossdomain.xml'
    file = Mechanize::File.new uri

    @mech.get('http://localhost', [], file)

    # HACK no assertion of behavior
  end

  def test_get_referer_none
    requests = []
    @mech.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @mech.get('http://localhost/')
    @mech.get('http://localhost/')
    assert_equal(2, requests.length)
    requests.each do |request|
      assert_nil request['referer']
    end
  end

  def test_get_scheme_unsupported
    assert_raises Mechanize::UnsupportedSchemeError do
      @mech.get('ftp://server.com/foo.html')
    end
  end

  def test_get_space
    page = nil

    page = @mech.get("http://localhost/tc_bad_links.html ")

    assert_match(/tc_bad_links.html$/, @mech.history.last.uri.to_s)

    assert_equal(1, @mech.history.length)
  end

  def test_get_tilde
    page = @mech.get('http://localhost/?foo=~2')

    assert_equal('http://localhost/?foo=~2', page.uri.to_s)
  end

  def test_get_weird
    @mech.get('http://localhost/?action=bing&bang=boom=1|a=|b=|c=')
    @mech.get('http://localhost/?a=b&#038;b=c&#038;c=d')
    @mech.get("http://localhost/?a=#{[0xd6].pack('U')}")

    # HACK no assertion of behavior
  end

  def test_get_yield
    pages = nil

    @mech.get("http://localhost/file_upload.html") { |page|
      pages = page
    }

    assert pages
    assert_equal('File Upload Form', pages.title)
  end

  def test_head
    page = @mech.head('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 0, @mech.history.length
    assert_equal 'HEAD', page.header['X-Request-Method']
  end

  def test_head_redirect
    page = @mech.head('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'HEAD', page.header['X-Request-Method']
  end

  def test_history
    2.times do |i|
      assert_equal(i, @mech.history.size)

      @mech.get("http://localhost/")
    end

    page = @mech.get("http://localhost/form_test.html")

    assert_equal("http://localhost/form_test.html",
      @mech.history.last.uri.to_s)
    assert_equal("http://localhost/",
      @mech.history[-2].uri.to_s)

    assert @mech.visited?("http://localhost/")
    assert @mech.visited?("/form_test.html"), 'relative'
    assert !@mech.visited?("http://google.com/")
    assert @mech.visited?(page.links.first)
  end

  def test_history_order
    @mech.max_history = 2
    assert_equal(0, @mech.history.length)

    @mech.get('http://localhost/form_test.html')
    assert_equal(1, @mech.history.length)

    @mech.get('http://localhost/empty_form.html')
    assert_equal(2, @mech.history.length)

    @mech.get('http://localhost/tc_checkboxes.html')
    assert_equal(2, @mech.history.length)
    assert_equal('http://localhost/empty_form.html', @mech.history[0].uri.to_s)
    assert_equal('http://localhost/tc_checkboxes.html',
                 @mech.history[1].uri.to_s)
  end

  def test_html_parser_equals
    @mech.html_parser = {}
    assert_raises(NoMethodError) {
      @mech.get('http://localhost/?foo=~2').links
    }
  end

  def test_keep_alive_time
    assert_equal 0, @mech.keep_alive_time

    @mech.keep_alive_time = 1

    assert_equal 1, @mech.keep_alive_time
  end

  def test_max_history_equals
    @mech.max_history = 10
    0.upto(10) do |i|
      assert_equal(i, @mech.history.size)
      @mech.get("http://localhost/")
    end

    0.upto(10) do |i|
      assert_equal(10, @mech.history.size)
      @mech.get("http://localhost/")
    end
  end

  def test_open_timeout_equals
    @mech.open_timeout = 5

    assert_equal 5, @mech.open_timeout
  end

  def test_post_basic_auth
    requests = []

    @mech.pre_connect_hooks << proc { |agent, request|
      requests << request.class
    }

    @mech.basic_auth('user', 'pass')
    page = @mech.post("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
    assert_equal(2, requests.length)
    r1 = requests[0]
    r2 = requests[1]
    assert_equal(r1, r2)
  end

  def test_post_multipart
    page = @mech.post('http://localhost/file_upload', {
      :name       => 'Some file',
      :userfile1  => File.open(__FILE__)
    })

    name = File.basename __FILE__
    assert_match(
      "Content-Disposition: form-data; name=\"userfile1\"; filename=\"#{name}\"",
      page.body
    )
    assert page.body.length > File.read(__FILE__).length
  end

  def test_post_redirect
    page = @mech.post('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_put
    page = @mech.put('http://localhost/verb', 'foo')
    assert_equal 1, @mech.history.length
    assert_equal 'PUT', page.header['X-Request-Method']
  end

  def test_put_redirect
    page = @mech.put('http://localhost/redirect', 'foo')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_read_timeout_equals
    @mech.read_timeout = 5

    assert_equal 5, @mech.read_timeout
  end

  def test_set_proxy
    http = @mech.agent.http

    @mech.set_proxy 'localhost', 8080, 'user', 'pass'

    assert_equal 'localhost', @mech.proxy_addr
    assert_equal 8080,        @mech.proxy_port
    assert_equal 'user',      @mech.proxy_user
    assert_equal 'pass',      @mech.proxy_pass

    refute_same http, @mech.agent.http
  end

  def test_submit_bad_form_method
    page = @mech.get("http://localhost/bad_form_test.html")
    assert_raises ArgumentError do
      @mech.submit(page.forms.first)
    end
  end

  def test_submit_check_one
    page = @mech.get('http://localhost/tc_checkboxes.html')
    form = page.forms.first
    form.checkboxes_with(:name => 'green')[1].check

    page = @mech.submit(form)

    assert_equal(1, page.links.length)
    assert_equal('green:on', page.links.first.text)
  end

  def test_submit_check_two
    page = @mech.get('http://localhost/tc_checkboxes.html')
    form = page.forms.first
    form.checkboxes_with(:name => 'green')[0].check
    form.checkboxes_with(:name => 'green')[1].check

    page = @mech.submit(form)

    assert_equal(2, page.links.length)
    assert_equal('green:on', page.links[0].text)
    assert_equal('green:on', page.links[1].text)
  end

  def test_submit_enctype
    page = @mech.get("http://localhost/file_upload.html")
    assert_equal('multipart/form-data', page.forms[0].enctype)

    form = page.forms.first
    form.file_uploads.first.file_name = "#{BASE_DIR}/helper.rb"
    form.file_uploads.first.mime_type = "text/plain"
    form.file_uploads.first.file_data = "Hello World\n\n"

    page = @mech.submit(form)

    assert_match(
      "Content-Disposition: form-data; name=\"userfile1\"; filename=\"helper.rb\"",
      page.body
    )
    assert_match(
      "Content-Disposition: form-data; name=\"name\"",
      page.body
    )
    assert_match('Content-Type: text/plain', page.body)
    assert_match('Hello World', page.body)
    assert_match('foo[aaron]', page.body)
  end

  def test_submit_file_data
    page = @mech.get("http://localhost/file_upload.html")
    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "#{BASE_DIR}/helper.rb"
    form.file_uploads.first.file_data = File.open("#{BASE_DIR}/helper.rb", 'rb')

    page = @mech.submit(form)

    contents = File.open("#{BASE_DIR}/helper.rb", 'rb') { |f| f.read }
    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"helper.rb\"",
      page.body
    )
    assert_match(contents, page.body)
  end

  def test_submit_file_name
    page = @mech.get("http://localhost/file_upload.html")
    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "#{BASE_DIR}/helper.rb"

    page = @mech.submit(form)

    contents = File.open("#{BASE_DIR}/helper.rb", 'rb') { |f| f.read }
    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"helper.rb\"",
      page.body
    )
    assert_match(contents, page.body)
  end

  def test_submit_headers
    page = @mech.get 'http://localhost:2000/form_no_action.html'

    assert form = page.forms.first
    form.action = '/http_headers'

    page = @mech.submit form, nil, 'foo' => 'bar'

    headers = page.body.split("\n").map { |x| x.split('|', 2) }.flatten
    headers = Hash[*headers]

    assert_equal 'bar', headers['foo']
  end

  def test_submit_multipart
    page = @mech.get("http://localhost/file_upload.html")

    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "#{BASE_DIR}/helper.rb"
    form.file_uploads.first.mime_type = "text/plain"
    form.file_uploads.first.file_data = "Hello World\n\n"

    page = @mech.submit(form)

    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"helper.rb\"",
      page.body
    )
  end

  def test_submit_no_file
    page = @mech.get("http://localhost/file_upload.html")
    form = page.forms.first
    form.field_with(:name => 'name').value = 'Aaron'
    @page = @mech.submit(form)
    assert_match('Aaron', @page.body)
    assert_match(
      "Content-Disposition: form-data; name=\"userfile1\"; filename=\"\"",
      @page.body
    )
  end

  def test_submit_too_many_radiobuttons
    page = @mech.get("http://localhost/form_test.html")
    form = page.form_with(:name => 'post_form1')
    form.radiobuttons.each { |r| r.checked = true }

    assert_raises Mechanize::Error do
      @mech.submit(form)
    end
  end

  def test_transact
    @mech.get("http://localhost/frame_test.html")
    assert_equal(1, @mech.history.length)
    @mech.transact { |a|
      5.times {
        @mech.get("http://localhost/frame_test.html")
      }
      assert_equal(6, @mech.history.length)
    }
    assert_equal(1, @mech.history.length)
  end

  def test_user_agent_alias_equals_unknown
    assert_raises ArgumentError do
      @mech.user_agent_alias = "Aaron's Browser"
    end
  end

  def test_visited_eh
    @mech.get("http://localhost/content_type_test?ct=application/pdf")

    assert \
      @mech.visited?("http://localhost/content_type_test?ct=application/pdf")
    assert \
      !@mech.visited?("http://localhost/content_type_test")
    assert \
      !@mech.visited?("http://localhost/content_type_test?ct=text/html")
  end

  def test_visited_eh_redirect
    @mech.get("http://localhost/response_code?code=302")

    assert_equal("http://localhost/index.html", @mech.current_page.uri.to_s)

    assert @mech.visited?('http://localhost/response_code?code=302')
  end

  def assert_header(page, header)
    headers = {}

    page.body.split(/[\r\n]+/).each do |page_header|
      headers.[]=(*page_header.chomp.split(/\|/))
    end

    header.each do |key, value|
      assert(headers.has_key?(key))
      assert_equal(value, headers[key])
    end
  end
end

