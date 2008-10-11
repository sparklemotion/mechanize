module WWW
  class Mechanize
    ###
    # Fake response for dealing with file:/// requests
    class FileResponse
      def initialize(file_path)
        @file_path = file_path
      end

      def read_body
        if ::File.exists?(@file_path)
          if directory?
            yield dir_body
          else
            yield ::File.read(@file_path)
          end
        else
          yield ''
        end
      end

      def code
        ::File.exists?(@file_path) ? 200 : 400
      end

      def content_length
        return dir_body.length if directory?
        ::File.exists?(@file_path) ? ::File.stat(@file_path).size : 0
      end

      def each_header; end

      def [](key)
        return nil unless key.downcase == 'content-type'
        return 'text/html' if directory?
        return 'text/html' if ['.html', '.xhtml'].any? { |extn|
          @file_path =~ /#{extn}$/
        }
        nil
      end

      def each
      end

      def get_fields(key)
        []
      end

      private
      def dir_body
        '<html><body>' +
        Dir[::File.join(@file_path, '*')].map { |f|
          "<a href=\"file://#{f}\">#{::File.basename(f)}</a>"
        }.join("\n") + '</body></html>'
      end

      def directory?
        ::File.directory?(@file_path)
      end
    end
  end
end
