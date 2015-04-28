module Bigrig
  class Tar
    class << self
      def create_dir_tar(directory)
        tempfile = create_temp_file
        directory += '/' unless directory.end_with?('/')

        create_relative_dir_tar(directory, tempfile)

        File.new(tempfile.path, 'r')
      end

      def create_relative_dir_tar(directory, output)
        ignore_matchers = read_docker_ignore(directory).map { |x| GoMatcher.new x }

        Gem::Package::TarWriter.new(output) do |tar|
          Find.find(directory) do |prefixed_file_name|
            unprefixed_file_name = prefixed_file_name[directory.length..-1]
            ignore_matchers.detect { |x| x.matches? unprefixed_file_name } && next
            add_file tar, prefixed_file_name, unprefixed_file_name
          end
        end
      end

      def add_file(tar, prefixed_file_name, unprefixed_file_name)
        stat = File.stat(prefixed_file_name)

        stat.file? || return
        tar.add_file_simple(
          unprefixed_file_name, stat.mode, stat.size
        ) do |tar_file|
          IO.copy_stream(File.open(prefixed_file_name, 'rb'), tar_file)
        end
      end

      def create_temp_file
        tempfile_name = Dir::Tmpname.create('out') {}
        File.open(tempfile_name, 'wb+')
      end

      def read_docker_ignore(directory)
        File.read(File.join directory, '.dockerignore').split "\n"
      rescue Errno::ENOENT
        []
      end
    end
  end
end
