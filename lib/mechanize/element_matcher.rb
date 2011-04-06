module Mechanize::ElementMatcher

  def elements_with singular, plural = "#{singular}s"
    class_eval <<-CODE
      def #{plural}_with criteria = {}
        criteria = if String === criteria then
                     {:name => criteria}
                   else
                     criteria.map do |k, v|
                       k = :dom_id if k.to_sym == :id
                       [k, v]
                     end
                   end

        f = #{plural}.find_all do |thing|
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

      alias :#{singular} :#{singular}_with
    CODE
  end

end

