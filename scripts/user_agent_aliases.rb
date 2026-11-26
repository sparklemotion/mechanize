# frozen_string_literal: true

require 'mechanize'

##
# Updates the browser User-Agent strings in Mechanize::AGENT_ALIASES
# (lib/mechanize.rb) to the latest ones shown on WhatIsMyBrowser.com.

module UserAgentAliases
  URL = 'https://www.whatismybrowser.com/guides/the-latest-user-agent'
  DEFAULT_PATH = File.expand_path('../lib/mechanize.rb', __dir__)

  # Only the characters real User-Agent strings use, so that a string cannot
  # break out of the Ruby string literal or the pull request body.
  VALID_USER_AGENT = %r{\AMozilla/5\.0 [A-Za-z0-9 ().,:;_/-]+\z}.freeze

  # alias name => [page, heading above the table, text the wanted string contains]
  #
  # The first string that contains the text is used, so '' picks the first
  # string in the table.
  LOCATIONS = {
    'Linux Firefox' => ['firefox', 'Latest Firefox on Desktop User Agents', '(X11; Ubuntu; Linux x86_64;'],
    'Mac Firefox' => ['firefox', 'Latest Firefox on Desktop User Agents', '(Macintosh;'],
    'Mac Safari' => ['safari', 'Latest Safari on macOS User Agents', ''],
    'Windows Chrome' => ['chrome', 'Latest Chrome on Windows 10 User Agents', ''],
    'Windows Edge' => ['edge', 'Latest Edge on Windows User Agents', ''],
    'Windows Firefox' => ['firefox', 'Latest Firefox on Desktop User Agents', '(Windows NT'],
    'Android' => ['chrome', 'Latest Chrome on Android User Agents', ''],
    'iPhone' => ['safari', 'Latest Safari on iOS User Agents', '(iPhone;'],
    'iPad' => ['safari', 'Latest Safari on iOS User Agents', '(iPad;'],
  }.freeze

  class << self
    def update(path = DEFAULT_PATH)
      user_agents = user_agents_in(fetch_pages)
      source = File.read(path)
      File.write(path, rewrite_aliases(source, user_agents))
    end

    def fetch_pages
      agent = Mechanize.new

      pages = {}
      LOCATIONS.values.map(&:first).uniq.each do |name|
        sleep 1 unless pages.empty?
        pages[name] = agent.get("#{URL}/#{name}")
      end
      pages
    end

    def user_agents_in(pages)
      LOCATIONS.to_h do |alias_name, (page, heading, containing)|
        user_agents = pages.fetch(page).css("h2:contains('#{heading}') + .listing-of-useragents .code").map(&:text)
        user_agent = user_agents.find { |candidate| candidate.include?(containing) }
        raise "No User-Agent string for #{alias_name} under #{heading.inspect}" unless user_agent

        [alias_name, user_agent]
      end
    end

    def rewrite_aliases(source, user_agents)
      user_agents.reduce(source) do |updated, (alias_name, user_agent)|
        raise ArgumentError, "Not a valid User-Agent string for #{alias_name}" unless VALID_USER_AGENT.match?(user_agent)

        entries = updated.scan(/^\s*'#{Regexp.escape(alias_name)}' => '([^']*)',$/)
        raise ArgumentError, "Expected exactly one '#{alias_name}' entry, found #{entries.size}" unless entries.size == 1

        updated.sub("'#{alias_name}' => '#{entries[0][0]}',", "'#{alias_name}' => '#{user_agent}',")
      end
    end
  end
end
