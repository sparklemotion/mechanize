$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

Thread.new {
  require 'server'
}

#Thread.new {
#  require 'ssl_server'
#}

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
require 'tc_authenticate'
require 'tc_cookie_class'
require 'tc_cookie_jar'
require 'tc_errors'
require 'tc_save_file'
require 'tc_post_form'
require 'tc_pluggable_parser'
require 'tc_page'
require 'tc_form_no_inputname'
require 'tc_multi_select'
require 'tc_select_all'
require 'tc_select_none'
require 'tc_select'
require 'tc_select_noopts'
require 'tc_set_fields'
require 'tc_bad_links'
require 'tc_radiobutton'
require 'tc_checkboxes'
require 'tc_pretty_print'
require 'tc_no_attributes'
#require 'tc_proxy'
#require 'tc_ssl_server'

