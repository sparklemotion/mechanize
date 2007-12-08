module WWW
  class Mechanize
    class Form
      # This class represents a file upload field found in a form.  To use this
      # class, set WWW::FileUpload#file_data= to the data of the file you want
      # to upload and WWW::FileUpload#mime_type= to the appropriate mime type
      # of the file.
      # See the example in EXAMPLES[link://files/EXAMPLES_txt.html]
      class FileUpload < Field
        attr_accessor :file_name # File name
        attr_accessor :mime_type # Mime Type (Optional)
        
        alias :file_data :value
        alias :file_data= :value=
      
        def initialize(name, file_name)
          @file_name = Util.html_unescape(file_name)
          @file_data = nil
          super(name, @file_data)
        end
      end
    end
  end
end
