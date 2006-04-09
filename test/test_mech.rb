require 'fileutils'
require 'test/unit/testsuite'
require 'test/unit/ui/reporter'
require 'test/unit/ui/console/testrunner'

Thread.new {
require 'server'
}

fail "Missing results directory" if ARGV.empty?
html_dir = ARGV[0]

FileUtils.rm_r html_dir rescue nil
FileUtils.mkdir_p html_dir

Dir['tc_*.rb'].each do |fn|
  load fn
end

suite = Test::Unit::TestSuite.new
ObjectSpace.each_object(Class) do |cls|
  next if cls == Test::Unit::TestCase
  suite << cls.suite if cls.respond_to?(:suite)
end

Test::Unit::UI::Reporter.run(suite, html_dir)
