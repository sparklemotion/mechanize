require 'mechanize/test_case'

class TestNoAttributes < Mechanize::TestCase
  def test_parse_no_attributes
    @mech.get('http://localhost/tc_no_attributes.html')

    # HACK no assertions
  end
end
