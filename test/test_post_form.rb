require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class PostForm < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_post_form
    page = @agent.post("http://localhost/form_post",
                        'gender' => 'female'
                      )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:female" },
      "gender field missing"
    )
  end

  def test_post_form_multival
    page = @agent.post("http://localhost/form_post",
                       [ ['gender', 'female'],
                         ['gender', 'male']
                       ]
                      )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:female" },
      "gender field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
    assert_equal(2, page.links.length)
  end
end
