$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'webrick'
require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'servlets'

class FormsMechTest < Test::Unit::TestCase
  def setup
    @server = Thread.new {
      s = WEBrick::HTTPServer.new(
        :Port           => 0,
        :DocumentRoot   => Dir::pwd + "/htdocs",
        :Logger         => Logger.new(nil),
        :AccessLog      => Logger.new(nil)
      )
      @port = s.config[:Port]
      s.mount("/form_post", FormTest)
      s.mount("/form post", FormTest)

      s.start
    }

    begin
      Net::HTTP.get(URI.parse("http://localhost:#{@port}/"))
    rescue
      sleep 2
      retry
    end
  end

  def teardown
    Thread.kill(@server)
  end

  def test_post
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    post_form = page.forms.find { |f| f.name == "post_form1" }
    assert_not_nil(post_form, "Post form is null")
    assert_equal("post", post_form.method.downcase)
    assert_equal("/form_post", post_form.action)
    assert_equal(1, post_form.fields.size)
    assert_equal(1, post_form.buttons.size)
    assert_equal(2, post_form.radiobuttons.size)
    assert_equal(2, post_form.checkboxes.size)
    assert_not_nil(post_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(
    post_form.radiobuttons.find { |f| f.name == "gender" && f.value == "male"},
      "Gender male button was nil"
    )

    assert_not_nil(
    post_form.radiobuttons.find {|f| f.name == "gender" && f.value == "female"},
      "Gender female button was nil"
    )

    assert_not_nil(post_form.checkboxes.find { |f| f.name == "cool person" },
      "couldn't find cool person checkbox")
    assert_not_nil(post_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    post_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    post_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    post_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = agent.submit(post_form, post_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(3, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "first_name:Aaron" },
      "first_name field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
  end

  def test_get
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    get_form = page.forms.find { |f| f.name == "get_form1" }
    assert_not_nil(get_form, "Get form is null")
    assert_equal("get", get_form.method.downcase)
    assert_equal("/form_post", get_form.action)
    assert_equal(1, get_form.fields.size)
    assert_equal(1, get_form.buttons.size)
    assert_equal(2, get_form.radiobuttons.size)
    assert_equal(2, get_form.checkboxes.size)
    assert_not_nil(get_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(
    get_form.radiobuttons.find { |f| f.name == "gender" && f.value == "male"},
      "Gender male button was nil"
    )

    assert_not_nil(
    get_form.radiobuttons.find {|f| f.name == "gender" && f.value == "female"},
      "Gender female button was nil"
    )

    assert_not_nil(get_form.checkboxes.find { |f| f.name == "cool person" },
      "couldn't find cool person checkbox")
    assert_not_nil(get_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    get_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    get_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    get_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = agent.submit(get_form, get_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(3, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "first_name:Aaron" },
      "first_name field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
  end

  def test_post_with_space_in_action
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    post_form = page.forms.find { |f| f.name == "post_form2" }
    assert_not_nil(post_form, "Post form is null")
    assert_equal("post", post_form.method.downcase)
    assert_equal("/form post", post_form.action)
    assert_equal(1, post_form.fields.size)
    assert_equal(1, post_form.buttons.size)
    assert_equal(2, post_form.radiobuttons.size)
    assert_equal(2, post_form.checkboxes.size)
    assert_not_nil(post_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(
    post_form.radiobuttons.find { |f| f.name == "gender" && f.value == "male"},
      "Gender male button was nil"
    )

    assert_not_nil(
    post_form.radiobuttons.find {|f| f.name == "gender" && f.value == "female"},
      "Gender female button was nil"
    )

    assert_not_nil(post_form.checkboxes.find { |f| f.name == "cool person" },
      "couldn't find cool person checkbox")
    assert_not_nil(post_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    post_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    post_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    post_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = agent.submit(post_form, post_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(3, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "first_name:Aaron" },
      "first_name field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
  end

  def test_get_with_space_in_action
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    get_form = page.forms.find { |f| f.name == "get_form2" }
    assert_not_nil(get_form, "Get form is null")
    assert_equal("get", get_form.method.downcase)
    assert_equal("/form post", get_form.action)
    assert_equal(1, get_form.fields.size)
    assert_equal(1, get_form.buttons.size)
    assert_equal(2, get_form.radiobuttons.size)
    assert_equal(2, get_form.checkboxes.size)
    assert_not_nil(get_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(
    get_form.radiobuttons.find { |f| f.name == "gender" && f.value == "male"},
      "Gender male button was nil"
    )

    assert_not_nil(
    get_form.radiobuttons.find {|f| f.name == "gender" && f.value == "female"},
      "Gender female button was nil"
    )

    assert_not_nil(get_form.checkboxes.find { |f| f.name == "cool person" },
      "couldn't find cool person checkbox")
    assert_not_nil(get_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    get_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    get_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    get_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = agent.submit(get_form, get_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(3, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "first_name:Aaron" },
      "first_name field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
  end

  def test_post_with_param_in_action
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    post_form = page.forms.find { |f| f.name == "post_form3" }
    assert_not_nil(post_form, "Post form is null")
    assert_equal("post", post_form.method.downcase)
    assert_equal("/form_post?great day=yes&one=two", post_form.action)
    assert_equal(1, post_form.fields.size)
    assert_equal(1, post_form.buttons.size)
    assert_equal(2, post_form.radiobuttons.size)
    assert_equal(2, post_form.checkboxes.size)
    assert_not_nil(post_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(
    post_form.radiobuttons.find { |f| f.name == "gender" && f.value == "male"},
      "Gender male button was nil"
    )

    assert_not_nil(
    post_form.radiobuttons.find {|f| f.name == "gender" && f.value == "female"},
      "Gender female button was nil"
    )

    assert_not_nil(post_form.checkboxes.find { |f| f.name == "cool person" },
      "couldn't find cool person checkbox")
    assert_not_nil(post_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    post_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    post_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    post_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = agent.submit(post_form, post_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(3, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "first_name:Aaron" },
      "first_name field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
  end

  def test_get_with_param_in_action
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    get_form = page.forms.find { |f| f.name == "get_form3" }
    assert_not_nil(get_form, "Get form is null")
    assert_equal("get", get_form.method.downcase)
    assert_equal("/form_post?great day=yes&one=two", get_form.action)
    assert_equal(1, get_form.fields.size)
    assert_equal(1, get_form.buttons.size)
    assert_equal(2, get_form.radiobuttons.size)
    assert_equal(2, get_form.checkboxes.size)
    assert_not_nil(get_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(
    get_form.radiobuttons.find { |f| f.name == "gender" && f.value == "male"},
      "Gender male button was nil"
    )

    assert_not_nil(
    get_form.radiobuttons.find {|f| f.name == "gender" && f.value == "female"},
      "Gender female button was nil"
    )

    assert_not_nil(get_form.checkboxes.find { |f| f.name == "cool person" },
      "couldn't find cool person checkbox")
    assert_not_nil(get_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    get_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    get_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    get_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = agent.submit(get_form, get_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(5, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "first_name:Aaron" },
      "first_name field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "gender:male" },
      "gender field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "great day:yes" },
      "great day field missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "one:two" },
      "one field missing"
    )
  end
end
