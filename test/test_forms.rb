require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class FormsMechTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_no_form_action
    page = @agent.get('http://localhost:2000/form_no_action.html')
    page.forms.first.fields.first.value = 'Aaron'
    page = @agent.submit(page.forms.first)
    assert_match('/form_no_action.html?first=Aaron', page.uri.to_s)
  end

  def test_submit_takes_arbirary_headers
    page = @agent.get('http://localhost:2000/form_no_action.html')
    assert form = page.forms.first
    form.action = '/http_headers'
    page = @agent.submit(form, nil, { 'foo' => 'bar' })
    headers = Hash[*(
      page.body.split("\n").map { |x| x.split('|') }.flatten
    )]
    assert_equal 'bar', headers['foo']
  end

  # Test submitting form with two fields of the same name
  def test_post_multival
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'post_form')

    assert_not_nil(form)
    assert_equal(2, form.fields_with(:name => 'first').length)

    form.fields_with(:name => 'first')[0].value = 'Aaron'
    form.fields_with(:name => 'first')[1].value = 'Patterson'

    page = @agent.submit(form)

    assert_not_nil(page)

    assert_equal(2, page.links.length)
    assert_not_nil(page.link_with(:text => 'first:Aaron'))
    assert_not_nil(page.link_with(:text => 'first:Patterson'))
  end

  # Test calling submit on the form object
  def test_submit_on_form
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'post_form')

    assert_not_nil(form)
    assert_equal(2, form.fields_with(:name => 'first').length)

    form.fields_with(:name => 'first')[0].value = 'Aaron'
    form.fields_with(:name => 'first')[1].value = 'Patterson'

    page = form.submit

    assert_not_nil(page)

    assert_equal(2, page.links.length)
    assert_not_nil(page.link_with(:text => 'first:Aaron'))
    assert_not_nil(page.link_with(:text => 'first:Patterson'))
  end

  # Test submitting form with two fields of the same name
  def test_get_multival
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'get_form')

    assert_not_nil(form)
    assert_equal(2, form.fields_with(:name => 'first').length)

    form.fields_with(:name => 'first')[0].value = 'Aaron'
    form.fields_with(:name => 'first')[1].value = 'Patterson'

    page = @agent.submit(form)

    assert_not_nil(page)

    assert_equal(2, page.links.length)
    assert_not_nil(page.link_with(:text => 'first:Aaron'))
    assert_not_nil(page.link_with(:text => 'first:Patterson'))
  end

  def test_post_with_non_strings
    page = @agent.get("http://localhost/form_test.html")
    page.form('post_form1') do |form|
      form.first_name = 10
    end.submit
  end

  def test_post
    page = @agent.get("http://localhost/form_test.html")
    post_form = page.forms.find { |f| f.name == "post_form1" }
    assert_not_nil(post_form, "Post form is null")
    assert_equal("post", post_form.method.downcase)
    assert_equal("/form_post", post_form.action)

    assert_equal(3, post_form.fields.size)

    assert_equal(1, post_form.buttons.size)
    assert_equal(2, post_form.radiobuttons.size)
    assert_equal(3, post_form.checkboxes.size)
    assert_not_nil(post_form.fields.find { |f| f.name == "first_name" },
      "First name field was nil"
    )
    assert_not_nil(post_form.fields.find { |f| f.name == "country" },
      "Country field was nil"
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
    assert_not_nil(post_form.checkboxes.find { |f| f.name == "green[eggs]" },
      "couldn't find green[eggs] checkbox")

    # Find the select list
    s = post_form.fields.find { |f| f.name == "country" }
    assert_equal(2, s.options.length)
    assert_equal("USA", s.value)
    assert_equal("USA", s.options.first.value)
    assert_equal("USA", s.options.first.text)
    assert_equal("CANADA", s.options[1].value)
    assert_equal("CANADA", s.options[1].text)

    # Now set all the fields
    post_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    post_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    post_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    post_form.checkboxes.find { |f| f.name == "green[eggs]" }.checked = true
    page = @agent.submit(post_form, post_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(5, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "green[eggs]:on" },
      "green[eggs] check box missing"
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
      page.links.find { |l| l.text == "country:USA" },
      "select box not submitted"
    )
  end

  def test_post_multipart
    page = @agent.get("http://localhost/form_test.html")
    post_form = page.forms.find { |f| f.name == "post_form4_multipart" }
    assert_not_nil(post_form, "Post form is null")
    assert_equal("post", post_form.method.downcase)
    assert_equal("/form_post", post_form.action)
    
    assert_equal(1, post_form.fields.size)
    assert_equal(1, post_form.buttons.size)
    
    page = @agent.submit(post_form, post_form.buttons.first)
    
    assert_not_nil(page)
  end

  def test_select_box
    page = @agent.get("http://localhost/form_test.html")
    post_form = page.forms.find { |f| f.name == "post_form1" }
    assert_not_nil(post_form, "Post form is null")
    assert_not_nil(page.header)
    assert_not_nil(page.root)
    assert_equal(0, page.iframes.length)
    assert_equal("post", post_form.method.downcase)
    assert_equal("/form_post", post_form.action)

    # Find the select list
    s = post_form.field_with(:name => /country/)
    assert_not_nil(s, "Couldn't find country select list")
    assert_equal(2, s.options.length)
    assert_equal("USA", s.value)
    assert_equal("USA", s.options.first.value)
    assert_equal("USA", s.options.first.text)
    assert_equal("CANADA", s.options[1].value)
    assert_equal("CANADA", s.options[1].text)

    # Now set all the fields
    post_form.field_with(:name => /country/).value = s.options[1]
    assert_equal('CANADA', post_form.country)
    page = @agent.submit(post_form, post_form.buttons.first)

    # Check that the submitted fields exist
    assert_not_nil(
      page.links.find { |l| l.text == "country:CANADA" },
      "select box not submitted"
    )
  end

  def test_get
    page = @agent.get("http://localhost/form_test.html")
    get_form = page.forms.find { |f| f.name == "get_form1" }
    assert_not_nil(get_form, "Get form is null")
    assert_equal("get", get_form.method.downcase)
    assert_equal("/form_post", get_form.action)
    assert_equal(1, get_form.fields.size)
    assert_equal(2, get_form.buttons.size)
    assert_equal(2, get_form.radiobuttons.size)
    assert_equal(3, get_form.checkboxes.size)
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
    assert_not_nil(get_form.checkboxes.find { |f| f.name == "green[eggs]" },
      "couldn't find green[eggs] checkbox")

    # Set up the image button
    img = get_form.buttons.find { |f| f.name == "button" }
    img.x = "9"
    img.y = "10"
    # Now set all the fields
    get_form.fields.find { |f| f.name == "first_name" }.value = "Aaron"
    get_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    get_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    get_form.checkboxes.find { |f| f.name == "green[eggs]" }.checked = true
    page = @agent.submit(get_form, get_form.buttons.first)

    # Check that the submitted fields exist
    assert_equal(7, page.links.size, "Not enough links")
    assert_not_nil(
      page.links.find { |l| l.text == "likes ham:on" },
      "likes ham check box missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "green[eggs]:on" },
      "green[eggs] check box missing"
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
      page.links.find { |l| l.text == "button.y:10" },
      "Image button missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "button.x:9" },
      "Image button missing"
    )
    assert_not_nil(
      page.links.find { |l| l.text == "button:button" },
      "Image button missing"
    )
  end

  def test_post_with_space_in_action
    page = @agent.get("http://localhost/form_test.html")
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
    page = @agent.submit(post_form, post_form.buttons.first)

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
    page = @agent.get("http://localhost/form_test.html")
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
    page = @agent.submit(get_form, get_form.buttons.first)

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
    page = @agent.get("http://localhost/form_test.html")
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

    assert_not_nil(post_form.checkbox_with(:name => "cool person"),
      "couldn't find cool person checkbox")
    assert_not_nil(post_form.checkboxes.find { |f| f.name == "likes ham" },
      "couldn't find likes ham checkbox")

    # Now set all the fields
    post_form.field_with(:name => 'first_name').value = "Aaron"
    post_form.radiobuttons.find { |f| 
      f.name == "gender" && f.value == "male" 
    }.checked = true
    post_form.checkboxes.find { |f| f.name == "likes ham" }.checked = true
    page = @agent.submit(post_form, post_form.buttons.first)

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
    page = @agent.get("http://localhost/form_test.html")
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
    page = @agent.submit(get_form, get_form.buttons.first)
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

  def test_field_addition
    page = @agent.get("http://localhost/form_test.html")
    get_form = page.forms.find { |f| f.name == "get_form1" }
    get_form.field("first_name").value = "Gregory"
    assert_equal( "Gregory", get_form.field("first_name").value ) 
  end

  def test_fields_as_accessors
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'post_form')

    assert_not_nil(form)
    assert_equal(2, form.fields_with(:name => 'first').length)

    form.first = 'Aaron'
    assert_equal('Aaron', form.first)
  end

  def test_add_field
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'post_form')

    assert_not_nil(form)
    number_of_fields = form.fields.length

    f = form.add_field!('intarweb')
    assert_not_nil(f)
    assert_equal(number_of_fields + 1, form.fields.length)
  end
  
  def test_delete_field
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'post_form')

    assert_not_nil(form)
    number_of_fields = form.fields.length
    assert_equal 2, number_of_fields

    form.delete_field!('first')
    assert_nil(form['first'])
    assert_equal(number_of_fields - 2, form.fields.length)    
  end

  def test_has_field
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form_with(:name => 'post_form')

    assert_not_nil(form)
    assert_equal(false, form.has_field?('intarweb'))
    f = form.add_field!('intarweb')
    assert_not_nil(f)
    assert_equal(true, form.has_field?('intarweb'))
  end

  def test_field_error
    @page = @agent.get('http://localhost/empty_form.html')
    form = @page.forms.first
    assert_raise(NoMethodError) {
      form.foo = 'asdfasdf'
    }

    assert_raise(NoMethodError) {
      form.foo
    }
  end
end
