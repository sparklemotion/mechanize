module WWW
  class Mechanize
    class Chain
      class SSLResolver
        include WWW::Handler

        def initialize(ca_file, verify_callback, cert, key, pass)
          @ca_file = ca_file
          @verify_callback = verify_callback
          @cert = cert
          @key = key
          @pass = pass
        end

        def handle(ctx, params)
          uri       = params[:uri]
          http_obj  = params[:connection]

          ssl = nil
          if http_obj.instance_variable_defined?(:@ssl_context)
            http_obj.instance_variable_get(:@ssl_context)
          end

          if uri.scheme == 'https' && ! http_obj.started? && ! ssl.frozen?
            http_obj.use_ssl = true
            http_obj.verify_mode = OpenSSL::SSL::VERIFY_NONE
            if @ca_file
              http_obj.ca_file = @ca_file
              http_obj.verify_mode = OpenSSL::SSL::VERIFY_PEER
              http_obj.verify_callback = @verify_callback if @verify_callback
            end
            if @cert && @key
              http_obj.cert = OpenSSL::X509::Certificate.new(::File.read(@cert))
              http_obj.key  = OpenSSL::PKey::RSA.new(::File.read(@key), @pass)
            end
          end
          super
        end
      end
    end
  end
end
