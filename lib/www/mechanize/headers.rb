module WWW
  class Mechanize
    class Headers < Hash
      def [](key)
        super(key.downcase)
      end
      def []=(key, value)
        super(key.downcase, value)
      end
    end
  end
end
