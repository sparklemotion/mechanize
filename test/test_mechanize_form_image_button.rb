require 'helper'

class TestMechanizeFormImageButton < Test::Unit::TestCase

  def test_query_value
    button = Mechanize::Form::ImageButton.new 'name' => 'image_button'

    assert_equal [%w[image_button.x 0], %w[image_button.y 0]],
                 button.query_value
  end
end

