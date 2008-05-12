require 'yaml'

module WWW
  class Mechanize
    # This class is used to manage the Cookies that have been returned from
    # any particular website.
    class CookieJar
      attr_reader :jar

      def initialize
        @jar = {}
      end
    
      # Add a cookie to the Jar.
      def add(uri, cookie)
        return unless uri.host =~ /#{cookie.domain}$/i
        normal_domain = cookie.domain.downcase
        unless @jar.has_key?(normal_domain)
          @jar[normal_domain] = Hash.new
        end
    
        @jar[normal_domain][cookie.name] = cookie
        cleanup()
        cookie
      end
    
      # Fetch the cookies that should be used for the URI object passed in.
      def cookies(url)
        cleanup
        cookies = []
        url.path = '/' if url.path.empty?
        @jar.each_key do |domain|
          if url.host =~ /#{domain}$/i
            @jar[domain].each_key do |name|
              if url.path =~ /^#{@jar[domain][name].path}/
                if @jar[domain][name].expires.nil?
                  cookies << @jar[domain][name]
                elsif Time.now < @jar[domain][name].expires
                  cookies << @jar[domain][name]
                end
              end
            end
          end
        end
    
        cookies
      end
    
      def empty?(url)
        cookies(url).length > 0 ? false : true
      end

      def to_a
        cookies = []
        @jar.each_key do |domain|
          @jar[domain].each_key do |name|
            cookies << @jar[domain][name]
          end
        end
        cookies
      end

      # Save the cookie jar to a file in the format specified.
      #
      # Available formats:
      # :yaml  <- YAML structure
      # :cookiestxt  <- Mozilla's cookies.txt format
      def save_as(file, format = :yaml)
        ::File.open(file, "w") { |f|
          case format
          when :yaml:
            YAML::dump(@jar, f)
          when :cookiestxt:
            dump_cookiestxt(f)
          else
            raise "Unknown cookie jar file format"
          end
        }
      end

      # Load cookie jar from a file in the format specified.
      #
      # Available formats:
      # :yaml  <- YAML structure.
      # :cookiestxt  <- Mozilla's cookies.txt format
      def load(file, format = :yaml)
        @jar = ::File.open(file) { |f|
          case format
          when :yaml:
            YAML::load(f)
          when :cookiestxt:
            load_cookiestxt(f)
          else
            raise "Unknown cookie jar file format"
          end
        }
      end

      # Clear the cookie jar
      def clear!
        @jar = {}
      end


      # Read cookies from Mozilla cookies.txt-style IO stream
      def load_cookiestxt(io)
        now = Time.now
        fakeuri = Struct.new(:host)    # add_cookie wants something resembling a URI.
        
        io.each_line do |line|
          line.chomp!
          line.gsub!(/#.+/, '')
          fields = line.split("\t")
          
          next if fields.length != 7
          
          expires_seconds = fields[4].to_i
          begin
            expires = Time.at(expires_seconds)
          rescue
            next
            # Just in case we ever decide to support DateTime...
            # expires = DateTime.new(1970,1,1) + ((expires_seconds + 1) / (60*60*24.0))
          end
          next if expires < now
          
          c = WWW::Mechanize::Cookie.new(fields[5], fields[6])
          c.domain = fields[0]
          # Field 1 indicates whether the cookie can be read by other machines at the same domain.
          # This is computed by the cookie implementation, based on the domain value.
          c.path = fields[2]               # Path for which the cookie is relevant
          c.secure = (fields[3] == "TRUE") # Requires a secure connection
          c.expires = expires             # Time the cookie expires.
          c.version = 0                   # Conforms to Netscape cookie spec.
          
          add(fakeuri.new(c.domain), c)
        end
        @jar
      end
      
      # Write cookies to Mozilla cookies.txt-style IO stream
      def dump_cookiestxt(io)
        @jar.each_pair do |domain, cookies|
          cookies.each_pair do |name, cookie|
            fields = []
            fields[0] = cookie.domain
            
            if cookie.domain =~ /^\./
              fields[1] = "TRUE"
            else
              fields[1] = "FALSE"
            end
            
            fields[2] = cookie.path
            
            if cookie.secure == true
              fields[3] = "TRUE"
            else
              fields[3] = "FALSE"
            end
            
            fields[4] = cookie.expires.to_i.to_s
            
            fields[5] = cookie.name
            fields[6] = cookie.value
            io.puts(fields.join("\t"))
          end 
        end
      end

      private
      # Remove expired cookies
      def cleanup
        @jar.each_key do |domain|
          @jar[domain].each_key do |name|
            unless @jar[domain][name].expires.nil?
              if Time.now > @jar[domain][name].expires
                @jar[domain].delete(name)
              end
            end
          end
        end
      end
    end
  end
end
