require 'mechanize'
require 'ostruct'

# LatestUAFetcher fetches latest user agents from `WhatIsMyBrowser.com`.
# It can use to update `Mechanize::AGENT_ALIASES`.
class LatestUAFetcher
  attr_reader :user_agents

  USER_AGENT_TYPES = OpenStruct.new(
    linux_firefox: "Linux Firefox",
    mac_firefox: "Mac Firefox",
    mac_safari: "Mac Safari",
    windows_chrome: "Windows Chrome",
    windows_edge: "Windows Edge",
    windows_firefox: "Windows Firefox",
    android: "Android",
    iphone: "iPhone",
    ipad: "iPad",
  )

  BASE_URL = 'https://www.whatismybrowser.com/guides/the-latest-user-agent'

  def initialize
    @agent = Mechanize.new.tap { |a| a.user_agent_alias = 'Mac Firefox' }
    @user_agents = {}
  end

  def run
    return unless user_agents.empty?

    sleep_time = 1

    fetch_user_agents('chrome')
    fetch_user_agents('firefox')
    fetch_user_agents('safari')
    fetch_user_agents('edge')
  end

  def ordered_user_agents
    USER_AGENT_TYPES.to_h.values.each_with_object({}) do |type, ordered_user_agents|
      ordered_user_agents[type] = user_agents[type]
    end
  end

  private

  def fetch_user_agents(browser_name, sleep_time = 1)
    puts "fetch #{browser_name} UA..."
    send(browser_name)
    puts "sleeping... (#{sleep_time}s)"
    sleep sleep_time
  end

  def edge
    page = @agent.get("#{BASE_URL}/edge")

    windows_dom = page.css("h2:contains('Latest Edge on Windows User Agents')")

    @user_agents[USER_AGENT_TYPES.windows_edge] = windows_dom.css('+ .listing-of-useragents .code').first.text
  end

  def firefox
    page = @agent.get("#{BASE_URL}/firefox")

    desktop_dom = page.css("h2:contains('Latest Firefox on Desktop User Agents')")
    table_dom = desktop_dom.css('+ .listing-of-useragents')

    @user_agents[USER_AGENT_TYPES.linux_firefox] = table_dom.css('td:contains("Linux")').css("+ td .code:contains('Ubuntu; Linux x86_64')").text
    @user_agents[USER_AGENT_TYPES.windows_firefox] = table_dom.css('td:contains("Windows")').css('+ td .code').text
    @user_agents[USER_AGENT_TYPES.mac_firefox] = table_dom.css('td:contains("Macos")').css('+ td .code').text
  end

  def safari
    page = @agent.get("#{BASE_URL}/safari")

    macos_dom = page.css("h2:contains('Latest Safari on macOS User Agents')")
    ios_dom = page.css("h2:contains('Latest Safari on iOS User Agents')")

    @user_agents[USER_AGENT_TYPES.mac_safari] = macos_dom.css('+ .listing-of-useragents .code').first.text
    @user_agents[USER_AGENT_TYPES.iphone] = ios_dom.css('+ .listing-of-useragents').css("tr:contains('Iphone') .code").text
    @user_agents[USER_AGENT_TYPES.ipad] = ios_dom.css('+ .listing-of-useragents').css("tr:contains('Ipad') .code").text
  end

  def chrome
    page = @agent.get("#{BASE_URL}/chrome")

    windows_dom = page.css("h2:contains('Latest Chrome on Windows 10 User Agents')")
    android_dom = page.css("h2:contains('Latest Chrome on Android User Agents')")

    @user_agents[USER_AGENT_TYPES.windows_chrome] = windows_dom.css('+ .listing-of-useragents .code').first.text
    @user_agents[USER_AGENT_TYPES.android] = android_dom.css('+ .listing-of-useragents .code').first.text
  end
end

if $0 == __FILE__
  agent = LatestUAFetcher.new
  agent.run

  pp agent.ordered_user_agents
end
