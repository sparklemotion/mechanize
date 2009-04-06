module WWW
  class Mechanize
    class Chain
      class BodyDecodingHandler
        include WWW::Handler

        def handle(ctx, options)
          body = options[:response_body]
          response = options[:response]

          options[:response_body] = 
            if encoding = response['Content-Encoding']
              case encoding.downcase
              when 'gzip'
                Mechanize.log.debug('gunzip body') if Mechanize.log
                if response['Content-Length'].to_i > 0 || body.length > 0
                  begin
                    Zlib::GzipReader.new(body).read
                  rescue Zlib::BufError, Zlib::GzipFile::Error
                    if Mechanize.log
                      Mechanize.log.error('Caught a Zlib::BufError')
                    end
                    body.rewind
                    body.read(10)
                    Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(body.read)
                  rescue Zlib::DataError
                    if Mechanize.log
                      Mechanize.log.error("Caught a Zlib::DataError, unable to decode page: #{$!.to_s}")
                    end
                    ''
                  end
                else
                  ''
                end
              when 'x-gzip'
                body.read
              else
                raise 'Unsupported content encoding'
              end
            else
              body.read
            end
          super
        end
      end
    end
  end
end
