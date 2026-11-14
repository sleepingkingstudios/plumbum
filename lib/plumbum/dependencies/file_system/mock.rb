# frozen_string_literal: true

require 'plumbum/dependencies/file_system'

module Plumbum::Dependencies
  # Mock implementation of FileSystem for testing purposes.
  class FileSystem::Mock < Plumbum::Dependencies::FileSystem # rubocop:disable Metrics/ClassLength
    SINGLE_GLOB_PATTERN = /\*+/
    private_constant :SINGLE_GLOB_PATTERN

    # Exception raised when trying to read from or write to a non-mocked path.
    class InvalidPathError < StandardError; end

    # Utility class used to simulate tempfile behavior.
    class MockTempfile < SimpleDelegator
      # @param path [String] the qualified path to the tempfile.
      def initialize(path)
        super(StringIO.new)

        @path = path
      end

      # @return [String] the qualified path to the tempfile.
      attr_reader :path
    end

    # @param files [Hash{String => Hash, IO}] the mocked directories and files.
    #   Must be a Hash with String keys representing file path segments; Hash
    #   values represent directories, while IO values represent files.
    # @param root_path [String] the path to the root directory. Defaults to the
    #   value of `Dir.pwd`.
    def initialize(files: {}, root_path: Dir.pwd)
      super(root_path:)

      @files     = split_files(files)
      @tempfiles = []
    end

    # @return [Hash{String => Hash, IO}] the mocked directories and files.
    attr_reader :files

    # @return [Array<String>] the contents of each generated tempfile.
    attr_reader :tempfiles

    # (see Plumbum::Dependencies::FileSystem#create_directory)
    def create_directory(path, recursive: false) # rubocop:disable Metrics/MethodLength
      validate_file_path(path, as: 'path')

      *dir_names, dir_name = split_path(resolve_path(path))

      directory = write_directory(
        *dir_names,
        action:       'create directory',
        file_or_path: path,
        recursive:
      )

      if io_stream?(directory[dir_name])
        raise DirectoryIsAFileError,
          "unable to create directory #{path} - directory is a file"
      end

      directory[dir_name] ||= {}

      path
    end
    alias make_directory create_directory

    # (see Plumbum::Dependencies::FileSystem#delete_directory)
    def delete_directory(path, force: false, recursive: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      validate_file_path(path, as: 'path')

      *dir_names, dir_name = split_path(resolve_path(path))

      dir = dir_names.reduce(files) do |dir, dir_name|
        require_directory(action: 'delete directory', dir: dir[dir_name], path:)

        dir[dir_name]
      end

      require_directory(action: 'delete directory', dir: dir[dir_name], path:)

      is_empty =
        (recursive && empty_directories?(dir[dir_name])) || dir[dir_name].empty?

      if force || is_empty
        dir.delete(dir_name)

        return path
      end

      raise DirectoryNotEmptyError,
        "unable to delete directory #{path} - directory is not empty"
    end
    alias remove_directory delete_directory

    # (see Plumbum::Dependencies::FileSystem#delete_file)
    def delete_file(path) # rubocop:disable Metrics/MethodLength
      validate_file_path(path, as: 'path')

      resolved = resolve_path(path)

      if directory?(resolved)
        raise FileIsADirectoryError,
          "unable to delete file #{path} - file is a directory"
      end

      unless file?(resolved)
        raise FileNotFoundError,
          "unable to delete file #{path} - file not found"
      end

      *relative, file = split_path(resolved)

      directory = relative.empty? ? files : files.dig(*relative)

      directory.delete(file)

      path
    end
    alias remove_file delete_file

    # (see Plumbum::Dependencies::FileSystem#directory?)
    def directory?(path)
      validate_file_path(path, as: 'path')

      path = resolve_path(path)
      mock = resolve_mock(path)

      mock.is_a?(Hash)
    end
    alias directory_exists? directory?

    # (see Plumbum::Dependencies::FileSystem#each_file)
    def each_file(pattern, &) # rubocop:disable Metrics/AbcSize
      return enum_for(:each_file, pattern) unless block_given?

      absolute_path = pattern.is_a?(String) && pattern.start_with?(root_path)

      pattern = pattern[(root_path.length + 1)..] if absolute_path

      [*expanded_dirs, *flattened_files].each do |file_path|
        next unless matches_pattern?(file_path:, pattern:)

        yield absolute_path ? File.join(root_path, file_path) : file_path
      end

      nil
    end

    # @return [Array<String>] a list of the defined directory paths in the mock
    #   file system.
    def expanded_dirs = expand_dirs(files:).to_a.sort

    # @return [Array<String>] a list of the defined file paths in the mock file
    #   system.
    def flattened_files = flatten_files(files:).sort

    # (see Plumbum::Dependencies::FileSystem#directory?)
    def file?(path)
      validate_file_path(path, as: 'path')

      path = resolve_path(path)
      mock = resolve_mock(path)

      io_stream?(mock)
    end
    alias file_exists? file?

    # (see Plumbum::Dependencies::FileSystem#read_file)
    def read_file(file_or_path) # rubocop:disable Metrics/MethodLength
      validate_file(file_or_path, as: 'file')

      return file_or_path.read if io_stream?(file_or_path)

      path = resolve_path(file_or_path)

      unless path.start_with?(root_path)
        raise FileNotFoundError,
          "unable to read file #{file_or_path} - file not found"
      end

      mock = resolve_mock(path)

      return mock.tap(&:rewind).read if io_stream?(mock)

      if mock
        raise FileIsADirectoryError,
          "unable to read file #{file_or_path} - file is a directory"
      end

      raise FileNotFoundError,
        "unable to read file #{file_or_path} - file not found"
    end
    alias read read_file

    # (see Plumbum::Dependencies::FileSystem#with_tempfile)
    def with_tempfile(&block)
      file_name = SecureRandom.uuid
      file_path = File.join(root_path, 'tempfiles', file_name)

      tempfile = MockTempfile.new(file_path)

      (files['tempfiles'] ||= {})[file_name] = tempfile

      block.call(tempfile).tap do
        tempfiles << read_file(tempfile.tap(&:rewind))
      end
    ensure
      files['tempfiles'].delete(file_name)
    end

    # (see Plumbum::Dependencies::FileSystem#write_file)
    def write_file(file_or_path, data) # rubocop:disable Metrics/MethodLength
      validate_file(file_or_path, as: 'file')

      return file_or_path.write(data) if io_stream?(file_or_path)

      path = resolve_path(file_or_path)

      unless path.start_with?(root_path)
        raise DirectoryNotFoundError,
          "unable to write file #{file_or_path} - directory not found"
      end

      mock = resolve_mock(path)

      if mock.is_a?(MockTempfile)
        mock.write(data)
        mock.rewind

        return
      end

      if mock.nil? || io_stream?(mock)
        return write_mock_file(path, data, file_or_path)
      end

      raise FileIsADirectoryError,
        "unable to write file #{file_or_path} - file is a directory"
    end
    alias write write_file

    private

    def empty_directories?(dir)
      return false unless dir.is_a?(Hash)

      return true if dir.empty?

      dir.each_value.all? { |item| empty_directories?(item) }
    end

    def expand_dirs(files:, flat: Set.new, path: '')
      files.each do |name, value|
        qualified_path = path.empty? ? name : File.join(path, name)

        next unless value.is_a?(Hash)

        flat << qualified_path

        qualified_path.split('/').reduce do |memo, segment|
          "#{memo}/#{segment}".tap { |str| flat << str }
        end

        expand_dirs(files: value, flat:, path: qualified_path)
      end

      flat
    end

    def flatten_files(files:, flat: [], path: '')
      files.each do |name, value|
        qualified_path = path.empty? ? name : File.join(path, name)

        next flat << qualified_path unless value.is_a?(Hash)

        flatten_files(files: value, flat:, path: qualified_path)
      end

      flat
    end

    def io_stream?(file_or_path)
      super || file_or_path.is_a?(MockTempfile)
    end

    def matches_globbed_pattern?(entry_names:, pattern_strings:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      prefix_index   = pattern_strings.index { |str| str.include?('**') }
      prefix_strings = pattern_strings[...prefix_index]
      prefix_count   = prefix_strings.length
      suffix_index   = pattern_strings.rindex { |str| str.include?('**') }
      suffix_strings = pattern_strings[(1 + suffix_index)..]
      suffix_count   = suffix_strings.length

      return false unless entry_names.length >= prefix_count + suffix_count

      matchers = entry_names[...prefix_count].zip(prefix_strings)

      if suffix_count.zero?
        # For a globbed pattern, if there is no suffix there must still be at
        # least one entry to match the '**' pattern.
        matchers.push([entry_names[prefix_count], '*'])
      else
        matchers.concat(entry_names[-suffix_count...].zip(suffix_strings))
      end

      matchers.all? do |entry_name, pattern_string|
        matches_pattern_string?(entry_name:, pattern_string:)
      end
    end

    def matches_pattern?(file_path:, pattern:)
      entry_names     = file_path.split(File::SEPARATOR)
      pattern_strings = pattern.split(File::SEPARATOR)

      if pattern_strings.any? { |str| str.include?('**') }
        return matches_globbed_pattern?(entry_names:, pattern_strings:)
      end

      return false unless entry_names.length == pattern_strings.length

      entry_names.zip(pattern_strings).all? do |entry_name, pattern_string|
        matches_pattern_string?(entry_name:, pattern_string:)
      end
    end

    def matches_pattern_string?(entry_name:, pattern_string:)
      if pattern_string.include?('*')
        pattern_string
          .gsub('.', '\.')
          .gsub(SINGLE_GLOB_PATTERN, '.*')
          .then { |str| Regexp.new(str) }
          .match?(entry_name)
      else
        entry_name == pattern_string
      end
    end

    def require_directory(action:, dir:, path:)
      if io_stream?(dir)
        raise DirectoryIsAFileError,
          "unable to #{action} #{path} - directory is a file"
      elsif dir.nil?
        raise DirectoryNotFoundError,
          "unable to #{action} #{path} - directory not found"
      end
    end

    def resolve_mock(path)
      return unless path.start_with?(root_path)

      *rest, last = split_path(path)

      dir = rest.reduce(files) do |dir, segment|
        break if dir[segment].nil? || io_stream?(dir[segment])

        dir[segment]
      end

      dir&.[](last)
    end

    def split_files(files) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      files.each.with_object({}) do |(key, value), hsh|
        value = split_files(value)  if value.is_a?(Hash)
        value = StringIO.new(value) if value.is_a?(String)

        next hsh[key] = value unless key.include?('/')

        # Normalize key, removing root path and leading slash.
        key = key[root_path.length..] if key.start_with?(root_path)
        key = key[1..]                if key.start_with?('/')

        *dir, file = key.split('/')

        # Ensure that each directory is represented by a Hash.
        dir.each do |segment|
          hsh[segment] = {} unless hsh.key?(segment)

          raise "invalid file path #{key}" unless hsh[segment].is_a?(Hash)

          hsh = hsh[segment]
        end

        # Assign the file or directory value.
        hsh[file] = value
      end
    end

    def split_path(path)
      path[(1 + root_path.length)..]
        &.split(File::SEPARATOR) || []
    end

    def write_directory(*dir_names, action:, file_or_path:, recursive: false)
      dir_names.reduce(files) do |dir, dir_name|
        if io_stream?(dir[dir_name])
          raise DirectoryIsAFileError,
            "unable to #{action} #{file_or_path} - directory is a file"
        elsif dir[dir_name].nil? && !recursive
          raise DirectoryNotFoundError,
            "unable to #{action} #{file_or_path} - directory not found"
        end

        dir[dir_name] ||= {}
      end
    end

    def write_mock_file(path, data, file_or_path)
      *dir_names, file_name = split_path(path)

      directory = write_directory(
        *dir_names,
        action:       'write file',
        file_or_path:,
        recursive:    false
      )

      directory[file_name] = StringIO.new(data.to_s)
    end

    def validate_file(file_or_path, as:)
      return if file_or_path.is_a?(MockTempfile)

      super
    end
  end
end
