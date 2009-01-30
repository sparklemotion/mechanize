module WWW
  class Mechanize
    class Chain
      class AuthHeaders
        include WWW::Handler

        @@nonce_count = Hash.new(0)
        CNONCE = Digest::MD5.hexdigest("%x" % (Time.now.to_i + rand(65535)))

        def initialize(auth_hash, user, password, digest)
          @auth_hash = auth_hash
          @user      = user
          @password  = password
          @digest    = digest
        end

        def handle(ctx, params)
          uri     = params[:uri]
          request = params[:request]

          if( @auth_hash[uri.host] )
            case @auth_hash[uri.host]
            when :basic
              request.basic_auth(@user, @password)
            when :iis_digest
                digest_response = self.gen_auth_header(uri,request, @digest, true)
                request['Authorization'] = digest_response
            when :digest
              if @digest
                digest_response = self.gen_auth_header(uri,request, @digest)
                request['Authorization'] = digest_response
              end
            end
          end
          super
        end

        def gen_auth_header(uri, request, auth_header, is_IIS = false)
          auth_header =~ /^(\w+) (.*)/
  
          params = {}
          $2.gsub(/(\w+)=("[^"]*"|[^,]*)/) {
            params[$1] = $2.gsub(/^"/, '').gsub(/"$/, '')
          }
  
          @@nonce_count[params['nonce']] += 1

          a_1 = "#{@user}:#{params['realm']}:#{@password}"
          a_2 = "#{request.method}:#{uri.path}"
          request_digest = ''
          request_digest << Digest::MD5.hexdigest(a_1)
          request_digest << ':' << params['nonce']
          request_digest << ':' << ('%08x' % @@nonce_count[params['nonce']])
          request_digest << ':' << CNONCE
          request_digest << ':' << params['qop']
          request_digest << ':' << Digest::MD5.hexdigest(a_2)
  
          header = ''
          header << "Digest username=\"#{@user}\", "
          if is_IIS then
            header << "qop=\"#{params['qop']}\", "
          else
            header << "qop=#{params['qop']}, "
          end
          header << "uri=\"#{uri.path}\", "
          header << %w{ algorithm opaque nonce realm }.map { |field|
            next unless params[field]
            "#{field}=\"#{params[field]}\""
          }.compact.join(', ')

          header << "nc=#{'%08x' % @@nonce_count[params['nonce']]}, "
          header << "cnonce=\"#{CNONCE}\", "
          header << "response=\"#{Digest::MD5.hexdigest(request_digest)}\""
  
          return header
        end
      end
    end
  end
end
