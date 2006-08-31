$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'mechanize'

agent = WWW::Mechanize.new

# Get the flickr sign in page
page  = agent.get('http://flickr.com/signin/flickr/')

# Fill out the login form
form  = page.forms.name('flickrloginform').first
form.email = ARGV[0]
form.password = ARGV[1]
page  = agent.submit(form)

# Go to the upload page
page  = agent.click page.links.text('Upload')

# Fill out the form
form  = page.forms.action('/photos_upload_process.gne').first
form.file_uploads.name('file1').first.file_name = ARGV[2]
agent.submit(form)
