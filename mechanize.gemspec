(in /Users/jdance/Projects/mechanize)
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mechanize}
  s.version = "1.0.1.pre"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Patterson", "Mike Dalessio"]
  s.date = %q{2010-08-26}
  s.description = %q{The Mechanize library is used for automating interaction with websites. 
Mechanize automatically stores and sends cookies, follows redirects,
can follow links, and submit forms.  Form fields can be populated and
submitted.  Mechanize also keeps track of the sites that you have visited as
a history.}
  s.email = ["aaronp@rubyforge.org", "mike.dalessio@gmail.com"]
  s.extra_rdoc_files = ["Manifest.txt", "CHANGELOG.rdoc", "EXAMPLES.rdoc", "FAQ.rdoc", "GUIDE.rdoc", "LICENSE.rdoc", "README.rdoc"]
  s.files = ["CHANGELOG.rdoc", "EXAMPLES.rdoc", "FAQ.rdoc", "GUIDE.rdoc", "LICENSE.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "examples/flickr_upload.rb", "examples/mech-dump.rb", "examples/proxy_req.rb", "examples/rubyforge.rb", "examples/spider.rb", "lib/mechanize.rb", "lib/mechanize/chain.rb", "lib/mechanize/chain/auth_headers.rb", "lib/mechanize/chain/body_decoding_handler.rb", "lib/mechanize/chain/connection_resolver.rb", "lib/mechanize/chain/custom_headers.rb", "lib/mechanize/chain/handler.rb", "lib/mechanize/chain/header_resolver.rb", "lib/mechanize/chain/parameter_resolver.rb", "lib/mechanize/chain/post_connect_hook.rb", "lib/mechanize/chain/pre_connect_hook.rb", "lib/mechanize/chain/request_resolver.rb", "lib/mechanize/chain/response_body_parser.rb", "lib/mechanize/chain/response_header_handler.rb", "lib/mechanize/chain/response_reader.rb", "lib/mechanize/chain/ssl_resolver.rb", "lib/mechanize/chain/uri_resolver.rb", "lib/mechanize/content_type_error.rb", "lib/mechanize/cookie.rb", "lib/mechanize/cookie_jar.rb", "lib/mechanize/file.rb", "lib/mechanize/file_response.rb", "lib/mechanize/file_saver.rb", "lib/mechanize/form.rb", "lib/mechanize/form/button.rb", "lib/mechanize/form/check_box.rb", "lib/mechanize/form/field.rb", "lib/mechanize/form/file_upload.rb", "lib/mechanize/form/image_button.rb", "lib/mechanize/form/multi_select_list.rb", "lib/mechanize/form/option.rb", "lib/mechanize/form/radio_button.rb", "lib/mechanize/form/select_list.rb", "lib/mechanize/headers.rb", "lib/mechanize/history.rb", "lib/mechanize/inspect.rb", "lib/mechanize/monkey_patch.rb", "lib/mechanize/page.rb", "lib/mechanize/page/base.rb", "lib/mechanize/page/frame.rb", "lib/mechanize/page/image.rb", "lib/mechanize/page/label.rb", "lib/mechanize/page/link.rb", "lib/mechanize/page/meta.rb", "lib/mechanize/pluggable_parsers.rb", "lib/mechanize/redirect_limit_reached_error.rb", "lib/mechanize/redirect_not_get_or_head_error.rb", "lib/mechanize/response_code_error.rb", "lib/mechanize/unsupported_scheme_error.rb", "lib/mechanize/util.rb", "test/chain/test_argument_validator.rb", "test/chain/test_auth_headers.rb", "test/chain/test_custom_headers.rb", "test/chain/test_header_resolver.rb", "test/chain/test_parameter_resolver.rb", "test/chain/test_request_resolver.rb", "test/chain/test_response_reader.rb", "test/data/htpasswd", "test/data/server.crt", "test/data/server.csr", "test/data/server.key", "test/data/server.pem", "test/helper.rb", "test/htdocs/alt_text.html", "test/htdocs/bad_form_test.html", "test/htdocs/button.jpg", "test/htdocs/empty_form.html", "test/htdocs/file_upload.html", "test/htdocs/find_link.html", "test/htdocs/form_multi_select.html", "test/htdocs/form_multival.html", "test/htdocs/form_no_action.html", "test/htdocs/form_no_input_name.html", "test/htdocs/form_select.html", "test/htdocs/form_select_all.html", "test/htdocs/form_select_none.html", "test/htdocs/form_select_noopts.html", "test/htdocs/form_set_fields.html", "test/htdocs/form_test.html", "test/htdocs/frame_test.html", "test/htdocs/google.html", "test/htdocs/iframe_test.html", "test/htdocs/index.html", "test/htdocs/link with space.html", "test/htdocs/meta_cookie.html", "test/htdocs/no_title_test.html", "test/htdocs/relative/tc_relative_links.html", "test/htdocs/tc_bad_charset.html", "test/htdocs/tc_bad_links.html", "test/htdocs/tc_base_link.html", "test/htdocs/tc_blank_form.html", "test/htdocs/tc_charset.html", "test/htdocs/tc_checkboxes.html", "test/htdocs/tc_encoded_links.html", "test/htdocs/tc_field_precedence.html", "test/htdocs/tc_follow_meta.html", "test/htdocs/tc_form_action.html", "test/htdocs/tc_links.html", "test/htdocs/tc_meta_in_body.html", "test/htdocs/tc_no_attributes.html", "test/htdocs/tc_pretty_print.html", "test/htdocs/tc_radiobuttons.html", "test/htdocs/tc_referer.html", "test/htdocs/tc_relative_links.html", "test/htdocs/tc_textarea.html", "test/htdocs/test_bad_encoding.html", "test/htdocs/unusual______.html", "test/servlets.rb", "test/ssl_server.rb", "test/test_authenticate.rb", "test/test_bad_links.rb", "test/test_blank_form.rb", "test/test_checkboxes.rb", "test/test_content_type.rb", "test/test_cookie_class.rb", "test/test_cookie_jar.rb", "test/test_cookies.rb", "test/test_encoded_links.rb", "test/test_errors.rb", "test/test_field_precedence.rb", "test/test_follow_meta.rb", "test/test_form_action.rb", "test/test_form_as_hash.rb", "test/test_form_button.rb", "test/test_form_no_inputname.rb", "test/test_forms.rb", "test/test_frames.rb", "test/test_get_headers.rb", "test/test_gzipping.rb", "test/test_hash_api.rb", "test/test_history.rb", "test/test_history_added.rb", "test/test_html_unscape_forms.rb", "test/test_if_modified_since.rb", "test/test_keep_alive.rb", "test/test_links.rb", "test/test_mech.rb", "test/test_mech_proxy.rb", "test/test_mechanize_file.rb", "test/test_meta.rb", "test/test_multi_select.rb", "test/test_no_attributes.rb", "test/test_option.rb", "test/test_page.rb", "test/test_pluggable_parser.rb", "test/test_post_form.rb", "test/test_pretty_print.rb", "test/test_radiobutton.rb", "test/test_redirect_limit_reached.rb", "test/test_redirect_verb_handling.rb", "test/test_referer.rb", "test/test_relative_links.rb", "test/test_request.rb", "test/test_response_code.rb", "test/test_save_file.rb", "test/test_scheme.rb", "test/test_select.rb", "test/test_select_all.rb", "test/test_select_none.rb", "test/test_select_noopts.rb", "test/test_set_fields.rb", "test/test_ssl_server.rb", "test/test_subclass.rb", "test/test_textarea.rb", "test/test_upload.rb", "test/test_util.rb", "test/test_verbs.rb", "test/test_headers.rb"]
  s.homepage = %q{http://mechanize.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mechanize}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{The Mechanize library is used for automating interaction with websites}
  s.test_files = ["test/chain/test_argument_validator.rb", "test/chain/test_auth_headers.rb", "test/chain/test_custom_headers.rb", "test/chain/test_header_resolver.rb", "test/chain/test_parameter_resolver.rb", "test/chain/test_request_resolver.rb", "test/chain/test_response_reader.rb", "test/test_authenticate.rb", "test/test_bad_links.rb", "test/test_blank_form.rb", "test/test_checkboxes.rb", "test/test_content_type.rb", "test/test_cookie_class.rb", "test/test_cookie_jar.rb", "test/test_cookies.rb", "test/test_encoded_links.rb", "test/test_errors.rb", "test/test_field_precedence.rb", "test/test_follow_meta.rb", "test/test_form_action.rb", "test/test_form_as_hash.rb", "test/test_form_button.rb", "test/test_form_no_inputname.rb", "test/test_forms.rb", "test/test_frames.rb", "test/test_get_headers.rb", "test/test_gzipping.rb", "test/test_hash_api.rb", "test/test_headers.rb", "test/test_history.rb", "test/test_history_added.rb", "test/test_html_unscape_forms.rb", "test/test_if_modified_since.rb", "test/test_links.rb", "test/test_mech.rb", "test/test_mech_proxy.rb", "test/test_mechanize_file.rb", "test/test_meta.rb", "test/test_multi_select.rb", "test/test_no_attributes.rb", "test/test_option.rb", "test/test_page.rb", "test/test_pluggable_parser.rb", "test/test_post_form.rb", "test/test_pretty_print.rb", "test/test_radiobutton.rb", "test/test_redirect_limit_reached.rb", "test/test_redirect_verb_handling.rb", "test/test_referer.rb", "test/test_relative_links.rb", "test/test_request.rb", "test/test_response_code.rb", "test/test_save_file.rb", "test/test_scheme.rb", "test/test_select.rb", "test/test_select_all.rb", "test/test_select_none.rb", "test/test_select_noopts.rb", "test/test_set_fields.rb", "test/test_ssl_server.rb", "test/test_subclass.rb", "test/test_textarea.rb", "test/test_upload.rb", "test/test_util.rb", "test/test_verbs.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.2.1"])
      s.add_runtime_dependency(%q<net-http-persistent>, ["~> 1.1"])
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<hoe>, [">= 2.6.1"])
    else
      s.add_dependency(%q<nokogiri>, [">= 1.2.1"])
      s.add_dependency(%q<net-http-persistent>, ["~> 1.1"])
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<hoe>, [">= 2.6.1"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 1.2.1"])
    s.add_dependency(%q<net-http-persistent>, ["~> 1.1"])
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<hoe>, [">= 2.6.1"])
  end
end
