task :tag do
  if File.read('lib/mechanize.rb') =~ /Version\s+=\s+"(\d+\.\d+\.\d+)"/
    version = $1 
  else
    raise "no version"
  end
  baseurl = "svn+ssh://ntecs.de/data/projects/svn/public/Mechanize"

  sh "svn cp -m 'tagged #{ version }' #{ baseurl }/trunk #{ baseurl }/tags/mechanize-#{ version }"
end

task :package do
  sh 'gem build mechanize.gemspec'
end
