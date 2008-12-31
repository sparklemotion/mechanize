module WWW
  class Mechanize
    class Util
      CODE_DIC = {
        :JIS => "ISO-2022-JP",
        :EUC => "EUC-JP", 
        :SJIS => "SHIFT_JIS",
        :UTF8 => "UTF-8", :UTF16 => "UTF-16", :UTF32 => "UTF-32"}

      class << self
        def build_query_string(parameters, enc=nil)
          #p parameters
          parameters.map { |k,v|
            if k
              [WEBrick::HTTPUtils.escape_form(k.to_s),
                WEBrick::HTTPUtils.escape_form(v.to_s)].join("=")
            end
          }.compact.join('&')
        end

        def to_utf8(s, code=nil)
          return unless s
          code ||= detect_charset(s)
          Iconv.iconv("UTF-8", code, s).join("")
        end

        def from_utf8(s, code)
          return unless s
          Iconv.iconv(code, "UTF-8", s).join("")
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

        def detect_charset(src)
          tmp = NKF.guess(src || "<html></html>")
          if RUBY_VERSION >= "1.9.0"
            enc = tmp.to_s.upcase
          else
            enc = NKF.constants.find{|c|
              NKF.const_get(c) == tmp
            }
            enc = CODE_DIC[enc.intern]
          end
          enc || "ASCII"
        end

      end
    end
  end
end
