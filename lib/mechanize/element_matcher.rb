module Mechanize::ElementMatcher

  def elements_with singular, plural = "#{singular}s"
    class_eval <<-CODE
      def #{plural}_with criteria = {}
        criteria = if String === criteria then
                     {:name => criteria}
                   else
                     Hash[criteria.map do |k, v|
                            k = :dom_id if k.to_sym == :id
                            k = :dom_class if k.to_sym == :class
                            [k, v]
                          end]
                   end

        f = select_#{plural}(criteria.delete(:search)).find_all do |thing|
          criteria.all? do |k,v|
            v === thing.send(k)
          end
        end
        yield f if block_given?
        f
      end

      def #{singular}_with criteria = {}
        f = #{plural}_with(criteria).first
        yield f if block_given?
        f
      end

      def #{singular}_with! criteria = {}
        f = #{singular}_with(criteria)
        raise Mechanize::ElementNotFoundError.new(self, :#{singular}, criteria) if f.nil?
        yield f if block_given?
        f
      end

      def select_#{plural} selector
        if selector.nil? then
          #{plural}
        else
          nodes = search(selector)
          #{plural}.find_all do |element|
            nodes.include?(element.node)
          end
        end
      end

      alias :#{singular} :#{singular}_with
    CODE
  end

end

