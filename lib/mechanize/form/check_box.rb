##
# This class represents a check box found in a Form.  To activate the CheckBox
# in the Form, set the checked method to true.

class Mechanize::Form::CheckBox < Mechanize::Form::RadioButton

  def query_value
    [[@name, @value || "on"]]
  end

end

