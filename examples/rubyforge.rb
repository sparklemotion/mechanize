$LOAD_PATH.unshift '../lib'
require 'mechanize'

agent = WWW::Mechanize.new {|a| a.log = Logger.new(STDERR) }
page = agent.get('http://rubyforge.org/')
link = page.links.find {|l| l.node.text =~ /Log In/ }
page = agent.click(link)
form = page.forms[1]
form.fields.find {|f| f.name == 'form_loginname'}.value = ARGV[0]
form.fields.find {|f| f.name == 'form_pw'}.value = ARGV[1]
page = agent.submit(form, form.buttons.first)

puts page.body
