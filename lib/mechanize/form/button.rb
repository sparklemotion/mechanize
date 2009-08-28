class Mechanize
  class Form
    # This class represents a Submit button in a form.
    class Button < Field ; end
    class Submit < Button; end
    class Reset  < Button; end
  end
end

