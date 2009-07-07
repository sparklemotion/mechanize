  class Mechanize
    class Page < Mechanize::File
      # This class encapsulates a Base tag.  Mechanize treats base tags just
      # like 'a' tags.  Base objects will contain links, but most likely will
      # have no text.
      class Base < Link; end
    end
  end
