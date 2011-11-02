require 'mechanize/test_case'

class TestFormAction < Mechanize::TestCase
  def setup
    super

    @page  = @mech.get("http://localhost/tc_form_action.html")
  end

  def test_post_with_bad_encoding_does_not_raise_exception
    @page  = @mech.get("http://localhost/test_bad_encoding.html")
    form = @page.form(:name => 'post_form1') { |f|
      f.first_name = "Aaron"
    }
    form.submit
  end

  def test_post_encoded_action
    form = @page.form(:name => 'post_form1') { |f|
      f.first_name = "Aaron"
    }
    assert_equal('/form_post?a=b&b=c', form.action)
    page = form.submit
    assert_equal("http://localhost/form_post?a=b&b=c", page.uri.to_s)
  end

  def test_get_encoded_action
    form = @page.form('post_form2') { |f|
      f.first_name = "Aaron"
    }
    assert_equal('/form_post?a=b&b=c', form.action)
    page = form.submit
    assert_equal("http://localhost/form_post?first_name=Aaron", page.uri.to_s)
  end

  def test_post_nonencoded_action
    form = @page.form('post_form3') { |f|
      f.first_name = "Aaron"
    }
    assert_equal('/form_post?a=b&b=c', form.action)
    page = form.submit
    assert_equal("http://localhost/form_post?a=b&b=c", page.uri.to_s)
  end

  def test_post_pound_sign
    form = @page.form('post_form4') { |f|
      f.first_name = "Aaron"
    }
    assert_equal('/form_post#1', form.action)
    page = form.submit
    assert_equal("http://localhost/form_post#1", page.uri.to_s)
  end
end
