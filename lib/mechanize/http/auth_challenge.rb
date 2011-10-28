class Mechanize::HTTP

  AuthChallenge = Struct.new :scheme, :params

  ##
  # A parsed WWW-Authenticate header

  class AuthChallenge

    ##
    # :attr_accessor: scheme
    #
    # The authentication scheme

    ##
    # :attr_accessor: params
    #
    # The authentication parameters

    ##
    # :method: initialize(scheme = nil, params = nil)
    #
    # Creates a new AuthChallenge header with the given scheme and parameters

    ##
    # The reconstructed, normalized challenge

    def to_s
      "#{scheme} #{params.map { |param| param.join '=' }.join ', '}"
    end

  end

end

