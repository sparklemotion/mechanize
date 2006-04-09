$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

Thread.new {
require 'server'
}

require 'test/unit'
require 'tc_cookies'
require 'tc_forms'
require 'tc_mech'
require 'tc_links'
require 'tc_response_code'
require 'tc_upload'
require 'tc_forms'
require 'tc_watches'
require 'tc_parsing'

