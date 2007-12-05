module WWW
  class Mechanize
    ##
    # This class manages history for your mechanize object.
    class History < Array
      attr_accessor :max_size

      def initialize(max_size = nil)
        @max_size       = max_size
        @history_index  = {}
      end

      def initialize_copy(orig)
        super
        @history_index = orig.instance_variable_get(:@history_index).dup
      end

      def push(page, uri = nil)
        super(page)
        @history_index[(uri ? uri : page.uri).to_s] = page
        if @max_size && self.length > @max_size
          while self.length > @max_size
            self.shift
          end
        end
        self
      end
      alias :<< :push

      def visited?(url)
        ! visited_page(url).nil?
      end

      def visited_page(url)
        @history_index[(url.respond_to?(:uri) ? url.uri : url).to_s]
      end

      def clear
        @history_index.clear
        super
      end

      def shift
        return nil if length == 0
        page    = self[0]
        self[0] = nil
        super
        remove_from_index(page)
        page
      end

      def pop
        return nil if length == 0
        page = super
        remove_from_index(page)
        page
      end

      private
      def remove_from_index(page)
        @history_index.each do |k,v|
          @history_index.delete(k) if v == page
        end
      end
    end
  end
end
