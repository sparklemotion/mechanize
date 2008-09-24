require 'pp'

module WWW
  # :stopdoc:
  class Mechanize
    def pretty_print(q)
      q.object_group(self) {
        q.breakable
        q.pp cookie_jar
        q.breakable
        q.pp current_page
      }
    end

    class Page
      def pretty_print(q)
        q.object_group(self) {
          q.breakable
          q.group(1, '{url', '}') {q.breakable; q.pp uri }
          q.breakable
          q.group(1, '{meta', '}') {
            meta.each { |link| q.breakable; q.pp link }
          }
          q.breakable
          q.group(1, '{title', '}') { q.breakable; q.pp title }
          q.breakable
          q.group(1, '{iframes', '}') {
            iframes.each { |link| q.breakable; q.pp link }
          }
          q.breakable
          q.group(1, '{frames', '}') {
            frames.each { |link| q.breakable; q.pp link }
          }
          q.breakable
          q.group(1, '{links', '}') {
            links.each { |link| q.breakable; q.pp link }
          }
          q.breakable
          q.group(1, '{forms', '}') {
            forms.each { |form| q.breakable; q.pp form }
          }
        }
      end

      class Link
        def pretty_print(q)
          q.object_group(self) {
            q.breakable; q.pp text
            q.breakable; q.pp href
          }
        end
      end
    end

    class Form
      def pretty_print(q)
        q.object_group(self) {
          q.breakable; q.group(1, '{name', '}') { q.breakable; q.pp name }
          q.breakable; q.group(1, '{method', '}') { q.breakable; q.pp method }
          q.breakable; q.group(1, '{action', '}') { q.breakable; q.pp action }
          q.breakable; q.group(1, '{fields', '}') {
            fields.each do |field|
              q.breakable
              q.pp field
            end
          }
          q.breakable; q.group(1, '{radiobuttons', '}') {
            radiobuttons.each { |b| q.breakable; q.pp b }
          }
          q.breakable; q.group(1, '{checkboxes', '}') {
            checkboxes.each { |b| q.breakable; q.pp b }
          }
          q.breakable; q.group(1, '{file_uploads', '}') {
            file_uploads.each { |b| q.breakable; q.pp b }
          }
          q.breakable; q.group(1, '{buttons', '}') {
            buttons.each { |b| q.breakable; q.pp b }
          }
        }
      end

      class RadioButton
        def pretty_print_instance_variables
          [:@checked, :@name, :@value]
        end
      end
    end
  end
  # :startdoc:
end
