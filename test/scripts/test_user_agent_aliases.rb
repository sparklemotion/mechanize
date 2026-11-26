# frozen_string_literal: true

require 'mechanize/test_case'
require_relative '../../scripts/user_agent_aliases'

class TestUserAgentAliases < Mechanize::TestCase

  # Version 999 keeps these from ever matching the strings in lib/mechanize.rb.
  LATEST_USER_AGENTS = {
    'Linux Firefox' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:999.0) Gecko/20100101 Firefox/999.0',
    'Mac Firefox' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 15.8; rv:999.0) Gecko/20100101 Firefox/999.0',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_8_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/999.0 Safari/605.1.15',
    'Windows Chrome' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Safari/537.36',
    'Windows Edge' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Safari/537.36 Edg/999.0.0.0',
    'Windows Firefox' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:999.0) Gecko/20100101 Firefox/999.0',
    'Android' => 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Mobile Safari/537.36',
    'iPhone' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_12 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/999.0 Mobile/15E148 Safari/604.1',
    'iPad' => 'Mozilla/5.0 (iPad; CPU OS 18_7_12 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/999.0 Mobile/15E148 Safari/604.1',
  }.freeze

  SOURCE = <<~RUBY
    AGENT_ALIASES = {
      'Mechanize' => "Mechanize/\#{VERSION} Ruby/\#{ruby_version} (http://github.com/sparklemotion/mechanize/)",

      'Linux Firefox' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:1.0) Gecko/20100101 Firefox/1.0',
      'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
      'Android' => 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/1.0.0.0 Mobile Safari/537.36',
    }
  RUBY

  # The other Linux string, the iPod string, and the ESR table look like the
  # wanted ones.

  def util_tables user_agents = LATEST_USER_AGENTS
    {
      'chrome' => {
        'Latest Chrome on Windows 10 User Agents' => [user_agents['Windows Chrome']],
        'Latest Chrome on Android User Agents' => [user_agents['Android']],
      },
      'firefox' => {
        'Latest Firefox on Desktop User Agents' => [
          user_agents['Windows Firefox'],
          user_agents['Mac Firefox'],
          'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:999.0) Gecko/20100101 Firefox/999.0',
          user_agents['Linux Firefox'],
        ],
        'Latest Firefox Extended Support Release (ESR) on Desktop User Agents' => [
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:998.0) Gecko/20100101 Firefox/998.0',
        ],
      },
      'safari' => {
        'Latest Safari on macOS User Agents' => [user_agents['Mac Safari']],
        'Latest Safari on iOS User Agents' => [
          user_agents['iPhone'],
          user_agents['iPad'],
          'Mozilla/5.0 (iPod touch; CPU iPhone 18_7_12 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/999.0 Mobile/15E148 Safari/604.1',
        ],
      },
      'edge' => {
        'Latest Edge on Windows User Agents' => [user_agents['Windows Edge']],
      },
    }
  end

  def util_pages tables = util_tables
    tables.to_h do |name, headings|
      html = headings.map do |heading, user_agents|
        items = user_agents.map { |user_agent| "<li><span class=\"code\">#{user_agent}</span></li>" }.join
        "<h2>#{heading}</h2><table class=\"listing-of-useragents\"><tr><td><ul>#{items}</ul></td></tr></table>"
      end.join

      [name, page("#{UserAgentAliases::URL}/#{name}", 'text/html', html)]
    end
  end

  def assert_invalid_user_agent user_agent
    e = assert_raises ArgumentError do
      UserAgentAliases.rewrite_aliases SOURCE, 'Android' => user_agent
    end

    assert_equal 'Not a valid User-Agent string for Android', e.message
  end

  def test_user_agents_in
    assert_equal LATEST_USER_AGENTS.to_a, UserAgentAliases.user_agents_in(util_pages).to_a
  end

  # The page is HTML, so a quote can come as an entity. It is decoded here and
  # rejected by rewrite_aliases, as in test_rewrite_aliases_single_quote.
  def test_user_agents_in_html_entity
    tables = util_tables LATEST_USER_AGENTS.merge('Android' => 'Mozilla/5.0 x&#39;, system(&#39;id&#39;), &#39;')

    user_agents = UserAgentAliases.user_agents_in util_pages(tables)

    assert_equal "Mozilla/5.0 x', system('id'), '", user_agents['Android']
  end

  def test_user_agents_in_no_match
    tables = util_tables
    tables['firefox']['Latest Firefox on Desktop User Agents'].delete LATEST_USER_AGENTS['Linux Firefox']

    e = assert_raises RuntimeError do
      UserAgentAliases.user_agents_in util_pages(tables)
    end

    assert_equal 'No User-Agent string for Linux Firefox under "Latest Firefox on Desktop User Agents"', e.message
  end

  def test_user_agents_in_heading_missing
    tables = util_tables
    tables['chrome'].delete 'Latest Chrome on Android User Agents'

    e = assert_raises RuntimeError do
      UserAgentAliases.user_agents_in util_pages(tables)
    end

    assert_equal 'No User-Agent string for Android under "Latest Chrome on Android User Agents"', e.message
  end

  def test_rewrite_aliases
    source = UserAgentAliases.rewrite_aliases SOURCE, 'Android' => LATEST_USER_AGENTS['Android']

    expected = <<~RUBY
      AGENT_ALIASES = {
        'Mechanize' => "Mechanize/\#{VERSION} Ruby/\#{ruby_version} (http://github.com/sparklemotion/mechanize/)",

        'Linux Firefox' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:1.0) Gecko/20100101 Firefox/1.0',
        'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        'Android' => 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/999.0.0.0 Mobile Safari/537.36',
      }
    RUBY
    assert_equal expected, source
  end

  def test_rewrite_aliases_twice
    user_agents = { 'Android' => LATEST_USER_AGENTS['Android'] }
    source = UserAgentAliases.rewrite_aliases SOURCE, user_agents

    assert_equal source, UserAgentAliases.rewrite_aliases(source, user_agents)
  end

  def test_rewrite_aliases_entry_missing
    e = assert_raises ArgumentError do
      UserAgentAliases.rewrite_aliases SOURCE, 'iPad' => LATEST_USER_AGENTS['iPad']
    end

    assert_equal "Expected exactly one 'iPad' entry, found 0", e.message
  end

  def test_rewrite_aliases_entry_duplicated
    source = SOURCE.sub(/^(  'Android' => .*\n)/, '\1\1')

    e = assert_raises ArgumentError do
      UserAgentAliases.rewrite_aliases source, 'Android' => LATEST_USER_AGENTS['Android']
    end

    assert_equal "Expected exactly one 'Android' entry, found 2", e.message
  end

  # Fails when AGENT_ALIASES in lib/mechanize.rb is reformatted so that its
  # entries can no longer be found, before the scheduled workflow fails.
  def test_rewrite_aliases_mechanize_rb
    source = File.read UserAgentAliases::DEFAULT_PATH

    updated = UserAgentAliases.rewrite_aliases source, LATEST_USER_AGENTS

    changed_lines = source.lines.zip(updated.lines).count { |before, after| before != after }
    assert_equal LATEST_USER_AGENTS.size, changed_lines
  end

  def test_rewrite_aliases_single_quote
    assert_invalid_user_agent "Mozilla/5.0 x', system('id'), '"
  end

  def test_rewrite_aliases_backslash
    assert_invalid_user_agent 'Mozilla/5.0 x\\'
  end

  def test_rewrite_aliases_backtick
    assert_invalid_user_agent 'Mozilla/5.0 ``` x'
  end

  def test_rewrite_aliases_mention
    assert_invalid_user_agent 'Mozilla/5.0 @someone'
  end

  def test_rewrite_aliases_html_tag
    assert_invalid_user_agent 'Mozilla/5.0 <script>'
  end

  def test_rewrite_aliases_trailing_newline
    assert_invalid_user_agent "#{LATEST_USER_AGENTS['Android']}\n"
  end

  def test_rewrite_aliases_other_prefix
    assert_invalid_user_agent 'Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.18'
  end

end
