module WWW
  class Mechanize
    class Util
      class << self
        def build_query_string(parameters)
          parameters.map { |k,v|
            k &&
              [WEBrick::HTTPUtils.escape_form(k.to_s),
                WEBrick::HTTPUtils.escape_form(v.to_s)].join("=")
          }.compact.join('&')
        end

        def html_unescape(s)
          return s unless s
          s.gsub(/&(\w+|#[0-9]+);/) { |match|
            number = case match
            when /&(\w+);/
              Mechanize.html_parser::NamedCharacters[$1]
            when /&#([0-9]+);/
              $1.to_i
            end
  
            number ? ([number].pack('U') rescue match) : match
          }
        end
      end
    end
  end
end
