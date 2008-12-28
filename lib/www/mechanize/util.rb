module WWW
  class Mechanize
    class Util
      class << self
        def build_query_string(parameters, enc=nil)
          parameters.map { |k,v|
            if k
              if enc
                k = Iconv.iconv(enc, "UTF-8", k.to_s)
                v = Iconv.iconv(enc, "UTF-8", v.to_s)
              end
              [WEBrick::HTTPUtils.escape_form(k.to_s),
                WEBrick::HTTPUtils.escape_form(v.to_s)].join("=")
            end
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
