# frozen_string_literal: true

require 'stringio'

require 'plumbum/dependencies/file_system/mock'
require 'plumbum/rspec/deferred/dependencies/file_system_examples'

RSpec.describe Plumbum::Dependencies::FileSystem::Mock do
  include Plumbum::RSpec::Deferred::Dependencies::FileSystemExamples

  subject(:mock_fs) { described_class.new(**options) }

  deferred_context 'when initialized with files' do
    let(:files)   { fixtures }
    let(:options) { super().merge(files:) }

    include_deferred 'with fixture files and directories'
  end

  deferred_context 'with valid file paths' do
    let(:maybe_root_path) { defined?(root_path) ? root_path : Dir.pwd }
    let(:absolute_directory_path) do
      File.join(maybe_root_path, 'root_dir')
    end
    let(:absolute_file_path) do
      File.join(maybe_root_path, 'root_file.txt')
    end
    let(:qualified_directory_path) do
      File.join(
        '..',
        File.split(maybe_root_path).last,
        'root_dir'
      )
    end
    let(:qualified_file_path) do
      File.join(
        '..',
        File.split(maybe_root_path).last,
        'root_file.txt'
      )
    end
    let(:relative_directory_path) do
      'root_dir'
    end
    let(:relative_file_path) do
      'root_file.txt'
    end

    include_deferred 'when initialized with files'
  end

  deferred_context 'when initialized with root_path: value' do
    let(:root_path)     { File.join(Plumbum.gem_path, 'tmp', 'files') }
    let(:options)       { super().merge(root_path:) }
    let(:fixtures_path) { root_path }
  end

  let(:options) { {} }

  describe '::InvalidPathError' do
    include_examples 'should define constant',
      :InvalidPathError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::MockTempfile' do
    subject(:tempfile) { described_class.new(path) }

    let(:described_class) { super()::MockTempfile }
    let(:path)            { 'path/to/tempfile' }

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#path' do
      include_examples 'should define reader', :path, -> { path }
    end

    describe '#read' do
      it { expect(tempfile.read).to be == '' }
    end

    describe '#write' do
      let(:value) { 'Contents of tempfile.' }

      it 'should update the file contents' do
        expect { tempfile.write(value) }.to(
          change { tempfile.tap(&:rewind).read }.to(be == value)
        )
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:files, :root_path)
    end
  end

  include_deferred 'should implement the file_system dependency'

  describe '#expanded_dirs' do
    it { expect(mock_fs).to respond_to(:expanded_dirs).with(0).arguments }

    it { expect(mock_fs.expanded_dirs).to be == [] }

    context 'when a directory is added to the file system' do
      let(:dir_path) { 'path/to/directory' }
      let(:expected_dirs) do
        %w[
          path
          path/to
          path/to/directory
        ]
      end

      before(:example) do
        mock_fs.expanded_dirs

        mock_fs.create_directory(dir_path, recursive: true)
      end

      it { expect(mock_fs.expanded_dirs).to be == expected_dirs }
    end

    wrap_deferred 'when initialized with files' do
      let(:expected_dirs) do
        %w[
          root_dir
          root_dir/child_dir
        ]
      end

      it { expect(mock_fs.expanded_dirs).to be == expected_dirs }

      context 'when a directory is added to the file system' do
        let(:dir_path) { 'path/to/directory' }
        let(:expected_dirs) do
          %w[
            path
            path/to
            path/to/directory
          ].concat(super())
        end

        before(:example) do
          mock_fs.expanded_dirs

          mock_fs.create_directory(dir_path, recursive: true)
        end

        it { expect(mock_fs.expanded_dirs).to be == expected_dirs }
      end
    end
  end

  describe '#files' do
    include_examples 'should define reader', :files, {}

    context 'when initialized with files with flattened paths' do
      let(:files) do
        {
          'root_dir/child_dir'      => {},
          'root_dir/child_file.txt' => StringIO.new('Child File'),
          'root_file.txt'           => StringIO.new('Root File')
        }
      end
      let(:expected) do
        {
          'root_dir'      => {
            'child_dir'      => {},
            'child_file.txt' => files['root_dir/child_file.txt']
          },
          'root_file.txt' => files['root_file.txt']
        }
      end
      let(:options) { super().merge(files:) }

      it { expect(mock_fs.files).to be == expected }
    end

    context 'when initialized with files starting with "/"' do
      let(:files) do
        {
          '/path/to/file' => StringIO.new('Nested File')
        }
      end
      let(:expected) do
        { 'path' => { 'to' => { 'file' => files['/path/to/file'] } } }
      end
      let(:options) { super().merge(files:) }

      it { expect(mock_fs.files).to be == expected }
    end

    context 'when initialized with files starting with the root path' do
      let(:files) do
        {
          "#{mock_fs.root_path}/path/to/file" => StringIO.new('Nested File')
        }
      end
      let(:expected) do
        {
          'path' => {
            'to' => {
              'file' => files["#{mock_fs.root_path}/path/to/file"]
            }
          }
        }
      end
      let(:options) { super().merge(files:) }

      it { expect(mock_fs.files).to be == expected }
    end

    context 'when initialized with files with String values' do
      let(:files) do
        {
          'file.txt'          => 'Top Level File',
          '/path/to/file.txt' => 'Flattened File',
          'directory'         => { 'file.txt' => 'Nested File' }
        }
      end
      let(:options) { super().merge(files:) }

      it 'should convert file contents to a StringIO', :aggregate_failures do
        file = mock_fs.files['file.txt']

        expect(file).to be_a(StringIO)
        expect(file.string).to be == 'Top Level File'
      end

      it 'should convert flattened file contents to a StringIO',
        :aggregate_failures \
      do
        file = mock_fs.files.dig('path', 'to', 'file.txt')

        expect(file).to be_a(StringIO)
        expect(file.string).to be == 'Flattened File'
      end

      it 'should convert nested file contents to a StringIO',
        :aggregate_failures \
      do
        file = mock_fs.files.dig('directory', 'file.txt')

        expect(file).to be_a(StringIO)
        expect(file.string).to be == 'Nested File'
      end
    end

    context 'when initialized with files with StringIO values' do
      let(:files) do
        {
          'file.txt'          => StringIO.new('Top Level File'),
          '/path/to/file.txt' => StringIO.new('Flattened File'),
          'directory'         => { 'file.txt' => StringIO.new('Nested File') }
        }
      end
      let(:options) { super().merge(files:) }

      it 'should accept file contents as a StringIO', :aggregate_failures do
        file = mock_fs.files['file.txt']

        expect(file).to be_a(StringIO)
        expect(file.string).to be == 'Top Level File'
      end

      it 'should accept flattened file contents as a StringIO',
        :aggregate_failures \
      do
        file = mock_fs.files.dig('path', 'to', 'file.txt')

        expect(file).to be_a(StringIO)
        expect(file.string).to be == 'Flattened File'
      end

      it 'should accept nested file contents as a StringIO',
        :aggregate_failures \
      do
        file = mock_fs.files.dig('directory', 'file.txt')

        expect(file).to be_a(StringIO)
        expect(file.string).to be == 'Nested File'
      end
    end
  end

  describe '#flattened_files' do
    it { expect(mock_fs).to respond_to(:flattened_files).with(0).arguments }

    it { expect(mock_fs.flattened_files).to be == [] }

    context 'when a file is added to the file system' do
      let(:file_path) { 'added_file.txt' }

      before(:example) do
        mock_fs.flattened_files

        mock_fs.write_file(file_path, 'This file was added in the test.')
      end

      it { expect(mock_fs.flattened_files).to be == [file_path] }
    end

    wrap_deferred 'when initialized with files' do
      let(:expected_files) do
        %w[
          root_dir/child_file.txt
          root_file.txt
        ]
      end

      it { expect(mock_fs.flattened_files).to be == expected_files }

      context 'when a file is added to the file system' do
        let(:file_path) { 'added_file.txt' }
        let(:expected_files) do
          (super() << file_path).sort
        end

        before(:example) do
          mock_fs.flattened_files

          mock_fs.write_file(file_path, 'This file was added in the test.')
        end

        it { expect(mock_fs.flattened_files).to be == expected_files }
      end
    end
  end

  describe '#tempfiles' do
    include_examples 'should define reader', :tempfiles, []
  end

  describe '#with_tempfile' do
    let(:contents) { "Greetings, programs!\n" }

    it 'should clean up the tempfile', :aggregate_failures do
      path = nil

      mock_fs.with_tempfile do |file|
        path = File.split(file.path).last

        expect(mock_fs.files['tempfiles']).to have_key(path)
      end

      expect(mock_fs.files['tempfiles']).not_to have_key(path)
    end

    it 'should copy the file contents to #tempfiles', :aggregate_failures do
      expect { mock_fs.with_tempfile { |file| file.write(contents) } }.to(
        change { mock_fs.tempfiles.size }.by(1)
      )

      expect(mock_fs.tempfiles.last).to be == contents
    end
  end

  describe '#write_file' do
    let(:data) { "Greetings, programs!\n" }

    describe 'with file: a mock Tempfile' do
      let(:tempfile) { described_class::MockTempfile.new('/path/to/file') }

      it 'should write the data to the tempfile' do
        expect { mock_fs.write_file(tempfile, data) }
          .to change(tempfile, :string)
          .to be == data
      end
    end

    describe 'with a path to a tempfile' do
      it 'should write the data to the tempfile', :aggregate_failures do
        mock_fs.with_tempfile do |tempfile|
          expect { mock_fs.write_file(tempfile.path, data) }
            .to change(tempfile, :string)
            .to be == data

          expect(tempfile.pos).to be 0
        end
      end
    end

    describe 'with a path to a file outside the root path' do
      let(:file) { File.join('invalid', 'path', 'to', 'file.txt') }
      let(:error_class) do
        Plumbum::Dependencies::FileSystem::DirectoryNotFoundError
      end
      let(:error_message) do
        "unable to write file #{file} - directory not found"
      end

      it 'should raise an exception' do
        expect { mock_fs.write_file(file, data) }
          .to raise_error error_class, error_message
      end
    end

    wrap_deferred 'when initialized with root_path: value' do
      describe 'with a path to a file outside the root path' do
        let(:file) do
          File.expand_path(
            File.join(root_path, '..', 'invalid', 'path', 'to', 'file.txt')
          )
        end
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::DirectoryNotFoundError
        end
        let(:error_message) do
          "unable to write file #{file} - directory not found"
        end

        it 'should raise an exception' do
          expect { mock_fs.write_file(file, data) }
            .to raise_error error_class, error_message
        end
      end
    end
  end
end
