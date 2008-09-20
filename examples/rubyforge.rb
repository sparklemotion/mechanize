$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# This example logs a user in to rubyforge and prints out the body of the
# page after logging the user in.
require 'rubygems'
require 'mechanize'

# Create a new mechanize object
agent = WWW::Mechanize.new { |a| a.log = Logger.new(STDERR) }

# Load the rubyforge website
page = agent.get('http://rubyforge.org/')
page = agent.click page.links.text(/Log In/) # Click the login link
form = page.forms[1] # Select the first form
form.form_loginname = ARGV[0]
form.form_pw        = ARGV[1]

# Submit the form
page = agent.submit(form, form.buttons.first)

puts page.body # Print out the body
