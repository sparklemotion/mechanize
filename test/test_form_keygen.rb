require "helper"

class TestFormKeygen < MiniTest::Unit::TestCase
  def setup
    @agent = Mechanize.new
    @page  = @agent.get("http://localhost/tc_keygen.html")
    @keygen = @page.forms.first.keygens.first
  end

  def test_challenge
    assert_equal "f4832e1d200df3df8c5c859edcabe52f", @keygen.challenge
  end
  
  def test_key
    assert @keygen.key.kind_of?(OpenSSL::PKey::PKey), "Not an OpenSSL key"
    assert @keygen.key.private?, "Not a private key"
  end

  def test_spki_signature
    spki = OpenSSL::Netscape::SPKI.new @keygen.value
    assert_equal @keygen.challenge, spki.challenge
    assert_equal @keygen.key.public_key.to_pem, spki.public_key.to_pem
    assert spki.verify(@keygen.key.public_key)
  end
end
