require 'cgi'
require 'nkf'

class Mechanize::Util
  # default mime type data for Page::Image#mime_type.
  # You can use another Apache-compatible mimetab.
  #   mimetab = WEBrick::HTTPUtils.load_mime_types('/etc/mime.types')
  #   Mechanize::Util::DefaultMimeTypes.replace(mimetab)
  DefaultMimeTypes = WEBrick::HTTPUtils::DefaultMimeTypes

  def self.build_query_string(parameters, enc = nil)
    parameters.map { |k,v|
      # WEBrick::HTTP.escape* has some problems about m17n on ruby-1.9.*.
      [CGI.escape(k.to_s), CGI.escape(v.to_s)].join("=") if k
    }.compact.join('&')
  end

  # Converts string +s+ from +code+ to UTF-8.
  def self.from_native_charset(s, code, ignore_encoding_error = false, log = nil)
    return s unless s && code
    return s unless Mechanize.html_parser == Nokogiri::HTML

    begin
      s.encode(code)
    rescue EncodingError => ex
      log.debug("from_native_charset: #{ex.class}: form encoding: #{code.inspect} string: #{s}") if log
      if ignore_encoding_error
        s
      else
        raise
      end
    end
  end

  def self.html_unescape(s)
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

  def self.detect_charset(src)
    if src
      NKF.guess(src).name.upcase
    else
      Encoding::ISO8859_1.name
    end
  end

  def self.uri_escape str, unsafe = nil
    @parser ||= begin
                  URI::Parser.new
                rescue NameError
                  URI
                end

    if URI == @parser then
      unsafe ||= URI::UNSAFE
    else
      unsafe ||= @parser.regexp[:UNSAFE]
    end

    @parser.escape str, unsafe
  end

  def self.uri_unescape str
    @parser ||= begin
                  URI::Parser.new
                rescue NameError
                  URI
                end

    @parser.unescape str
  end

end
