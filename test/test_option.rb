require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class OptionTest < Test::Unit::TestCase
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
    option = WWW::Mechanize::Form::Option.new(attribute, nil)
    assert_equal('blah', option.value)
  end
end
