##
# Unlike Mechanize::FileSaver, the directory saver places all downloaded files
# in a single pre-specified directory.
#
# You must register the directory to save to before using the directory saver:
#
#   agent.pluggable_parser['image'] = \
#     Mechanize::DirectorySaver.save_to 'images'

class Mechanize::DirectorySaver < Mechanize::Download

  @directory = nil

  ##
  # Creates a DirectorySaver subclass that will save responses to the given
  # +directory+.

  def self.save_to directory
    directory = File.expand_path directory

    Class.new self do |klass|
      klass.instance_variable_set :@directory, directory
    end
  end

  ##
  # The directory downloaded files will be saved to.

  def self.directory
    @directory
  end

  ##
  # Saves the +body_io+ into the directory specified for this DirectorySaver
  # by save_to.  The filename is chosen by Mechanize::Parser#extract_filename.

  def initialize uri = nil, response = nil, body_io = nil, code = nil
    directory = self.class.directory

    raise Mechanize::Error,
      'no save directory specified - ' \
      'use Mechanize::DirectorySaver.save_to ' \
      'and register the resulting class' unless directory

    super

    path = File.join directory, @filename

    save path
  end

end

