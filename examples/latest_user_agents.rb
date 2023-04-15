require 'mechanize'

class LatestUAFetcher
  attr_reader :user_agents

  BASE_URL = 'https://www.whatismybrowser.com/guides/the-latest-user-agent'

  def initialize
    @agent = Mechanize.new.tap { |a| a.user_agent_alias = 'Mac Firefox' }
    @user_agents = {}
  end

  def run
    sleep_time = 1

    puts 'get chrome UA...'
    chrome
    puts "sleeping... (#{sleep_time}s)"
    sleep 1

    puts 'get firefox UA...'
    firefox
    puts "sleeping... (#{sleep_time}s)"
    sleep 1

    puts 'get safari UA...'
    safari
    puts "sleeping... (#{sleep_time}s)"
    sleep 1

    puts 'get edge UA...'
    edge
  end

  private

  def edge
    page = @agent.get("#{BASE_URL}/edge")

    windows_dom = page.css("h2:contains('Latest Edge on Windows User Agents')")
    @user_agents[:edge] = {
      windows: windows_dom.css('+ .listing-of-useragents .code').first.text
    }
  end

  def firefox
    page = @agent.get("#{BASE_URL}/firefox")

    desktop_dom = page.css("h2:contains('Latest Firefox on Desktop User Agents')")
    table_dom = desktop_dom.css('+ .listing-of-useragents')

    @user_agents[:firefox] = {
      windows: table_dom.css('td:contains("Windows")').css('+ td .code').text,
      macOS: table_dom.css('td:contains("Macos")').css('+ td .code').text,
      linux: table_dom.css('td:contains("Linux")').css("+ td .code:contains('Ubuntu; Linux x86_64')").text
    }
  end

  def safari
    page = @agent.get("#{BASE_URL}/safari")

    macos_dom = page.css("h2:contains('Latest Safari on macOS User Agents')")
    ios_dom = page.css("h2:contains('Latest Safari on iOS User Agents')")

    @user_agents[:safari] = {
      mac_os: macos_dom.css('+ .listing-of-useragents .code').first.text,
      iphone: ios_dom.css('+ .listing-of-useragents').css("tr:contains('Iphone') .code").text,
      ipad: ios_dom.css('+ .listing-of-useragents').css("tr:contains('Ipad') .code").text
    }
  end

  def chrome
    page = @agent.get("#{BASE_URL}/chrome")

    windows_dom = page.css("h2:contains('Latest Chrome on Windows 10 User Agents')")
    linux_dom = page.css("h2:contains('Latest Chrome on Linux User Agents')")
    macos_dom = page.css("h2:contains('Latest Chrome on macOS User Agents')")
    android_dom = page.css("h2:contains('Latest Chrome on Android User Agents')")

    @user_agents[:chrome] = {
      windows: windows_dom.css('+ .listing-of-useragents .code').first.text,
      linux: linux_dom.css('+ .listing-of-useragents .code').first.text,
      mac_os: macos_dom.css('+ .listing-of-useragents .code').first.text,
      android: android_dom.css('+ .listing-of-useragents .code').first.text
    }
  end
end

agent = LatestUAFetcher.new
agent.run
p agent.user_agents
