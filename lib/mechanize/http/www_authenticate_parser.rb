# coding: BINARY

require 'strscan'

##
# Parses the WWW-Authenticate HTTP header into separate challenges.

class Mechanize::HTTP::WWWAuthenticateParser

  attr_accessor :scanner # :nodoc:

  ##
  # Creates a new header parser for WWW-Authenticate headers

  def initialize
    @scanner = nil
  end

  ##
  # Parsers the header.  Returns an Array of challenges as strings

  def parse www_authenticate
    challenges = []
    @scanner = StringScanner.new www_authenticate

    while true do
      break if @scanner.eos?
      challenge = Mechanize::HTTP::AuthChallenge.new

      scheme = auth_scheme
      next unless scheme
      challenge.scheme = scheme

      next unless spaces

      params = {}

      while true do
        pos = @scanner.pos
        name, value = auth_param

        unless name then
          challenge.params = params
          challenges << challenge
          break if @scanner.eos?

          @scanner.pos = pos # rewind
          challenge = '' # a token should be next, new challenge
          break
        else
          params[name] = value
        end

        spaces

        return nil unless ',' == @scanner.peek(1) or @scanner.eos?

        @scanner.scan(/(, *)+/)
      end
    end

    challenges
  end

  ##
  #   1*SP
  #
  # Parses spaces

  def spaces
    @scanner.scan(/ +/)
  end

  ##
  #   token = 1*<any CHAR except CTLs or separators>
  #
  # Parses a token

  def token
    @scanner.scan(/[^\000-\037\177()<>@,;:\\"\/\[\]?={} \t]+/)
  end

  ##
  #   auth-scheme = token
  #
  # Parses an auth scheme (a token)

  alias auth_scheme token

  ##
  #   auth-param = token "=" ( token | quoted-string )
  #
  # Parses an auth parameter

  def auth_param
    return nil unless name = token
    return nil unless @scanner.scan(/=/)

    value = if @scanner.peek(1) == '"' then
              quoted_string
            else
              token
            end

    return nil unless value

    return name, value
  end

  ##
  #   quoted-string = ( <"> *(qdtext | quoted-pair ) <"> )
  #   qdtext        = <any TEXT except <">>
  #   quoted-pair   = "\" CHAR
  #
  # For TEXT, the rules of RFC 2047 are ignored.

  def quoted_string
    return nil unless @scanner.scan /"/

    text = '"'

    while true do
      chunk = @scanner.scan(/[\r\n \t\041\043-\176\200-\377]+/) # not "

      if chunk then
        text << chunk

        text << @scanner.get_byte if
          chunk.end_with? '\\' and '"' == @scanner.peek(1)
      else
        if '"' == @scanner.peek(1) then
          text << @scanner.get_byte
          break
        else
          return nil
        end
      end
    end

    text
  end

end

