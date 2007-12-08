module WWW
  class Mechanize
    class Page < WWW::Mechanize::File
      # This class encapsulates a Meta tag.  Mechanize treats meta tags just
      # like 'a' tags.  Meta objects will contain links, but most likely will
      # have no text.
      class Meta < Link; end
    end
  end
end
