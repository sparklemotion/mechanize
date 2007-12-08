module WWW
  class Mechanize
    class Form
      # This class represents an image button in a form.  Use the x and y methods
      # to set the x and y positions for where the mouse "clicked".
      class ImageButton < Button
        attr_accessor :x, :y
        
        def initialize(name, value)
          @x = nil
          @y = nil
          super(name, value)
        end

        def query_value
            super <<
             [@name + ".x", (@x || 0).to_s] <<
             [@name + ".y", (@y || 0).to_s]
        end
      end
    end
  end
end
