require 'mechanize/test_case'

class MechanizeFormOptionTest < Mechanize::TestCase

  class FakeAttribute < Hash
    attr_reader :inner_text
    def initialize(inner_text)
      @inner_text = inner_text
    end
    alias :has_attribute? :has_key?
    alias :attributes :keys
  end

  def test_option_missing_value
    attribute = FakeAttribute.new('blah')
    option = Mechanize::Form::Option.new(attribute, nil)
    assert_equal('blah', option.value)
  end

end

