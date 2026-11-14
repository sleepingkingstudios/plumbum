# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'stringio'

require 'plumbum/dependencies/file_system'
require 'plumbum/rspec/deferred/dependencies/file_system_examples'

RSpec.describe Plumbum::Dependencies::FileSystem do
  include Plumbum::RSpec::Deferred::Dependencies::FileSystemExamples

  subject(:file_system) { described_class.new(**options) }

  deferred_context 'with valid file paths' do
    let(:fixtures_path) do
      File.join(Plumbum.gem_path, 'tmp', 'file_system')
    end
    let(:absolute_directory_path) { File.join(fixtures_path, 'root_dir') }
    let(:absolute_file_path)      { File.join(fixtures_path, 'root_file.txt') }
    let(:qualified_directory_path) do
      File.join(
        '..',
        *fixtures_path.split(File::SEPARATOR)[-3...],
        'root_dir'
      )
    end
    let(:qualified_file_path) do
      File.join(
        '..',
        *fixtures_path.split(File::SEPARATOR)[-3...],
        'root_file.txt'
      )
    end
    let(:relative_directory_path) do
      File.join(*fixtures_path.split(File::SEPARATOR)[-2...], 'root_dir')
    end
    let(:relative_file_path) do
      File.join(*fixtures_path.split(File::SEPARATOR)[-2...], 'root_file.txt')
    end

    define_method :build_fixture do |fixture, contents, path = nil|
      path ||= fixtures_path
      path = File.join(path, fixture)

      if contents.is_a?(Hash)
        FileUtils.mkdir_p(path)

        contents.each { |key, value| build_fixture(key, value, path) }
      else
        File.write(path, contents)
      end
    end

    define_method :read_fixture do |path|
      path = path.sub('tmp/file_system/', '')

      fixtures.dig(*path.split(File::SEPARATOR))
    end

    before(:example) do
      fixtures.each { |fixture, contents| build_fixture(fixture, contents) }
    end

    before(:example) do
      allow(Dir)
        .to receive(:glob)
        .and_wrap_original do |original, pattern, **options, &block|
          original.call(pattern, **options, base: fixtures_path, &block)
        end
    end

    after(:example) do
      relative_path = fixtures_path.sub(%r{#{Plumbum.gem_path}/?}, '')

      # :nocov:
      unless relative_path.start_with?('tmp/')
        raise "invalid temporary file path #{relative_path}"
      end
      # :nocov:

      FileUtils.remove_dir(fixtures_path, true)
    end

    include_deferred 'with fixture files and directories'
  end

  deferred_context 'when initialized with root_path: value' do
    let(:root_path) do
      File.join(Plumbum.gem_path, 'tmp', 'file_system', 'root_dir')
    end
    let(:options) { super().merge(root_path:) }
    let(:absolute_directory_path) do
      File.join(fixtures_path, 'root_dir', 'child_dir')
    end
    let(:qualified_directory_path) do
      File.join('..', 'root_dir', 'child_dir')
    end
    let(:qualified_file_path) do
      File.join('..', 'root_dir', 'child_file.txt')
    end
    let(:relative_directory_path) do
      'child_dir'
    end
    let(:relative_file_path) do
      'child_file.txt'
    end
  end

  let(:options)          { {} }
  let(:matching_entries) { [] }

  describe '::DirectoryIsAFileError' do
    include_examples 'should define constant',
      :DirectoryIsAFileError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::DirectoryNotEmptyError' do
    include_examples 'should define constant',
      :DirectoryNotEmptyError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::DirectoryNotFoundError' do
    include_examples 'should define constant',
      :DirectoryNotFoundError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::FileError' do
    include_examples 'should define constant',
      :FileError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::FileAlreadyExistsError' do
    include_examples 'should define constant',
      :FileAlreadyExistsError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::FileIsADirectoryError' do
    include_examples 'should define constant',
      :FileIsADirectoryError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '::FileNotFoundError' do
    include_examples 'should define constant',
      :FileNotFoundError,
      -> { be_a(Class).and(be < described_class::FileError) }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:root_path)
    end
  end

  include_deferred 'should implement the file_system dependency'

  describe '#each_file' do
    let(:pattern) { '**/*.rb' }

    before(:example) { allow(Dir).to receive(:glob).and_return([]) }

    it 'should delegate to Dir.glob' do
      file_system.each_file(pattern) { nil }

      expect(Dir)
        .to have_received(:glob)
        .with(pattern, base: file_system.root_path)
    end

    wrap_deferred 'when initialized with root_path: value' do
      it 'should delegate to Dir.glob' do
        file_system.each_file(pattern) { nil }

        expect(Dir)
          .to have_received(:glob)
          .with(pattern, base: file_system.root_path)
      end
    end
  end

  describe '#with_tempfile' do
    it 'should clean up the tempfile', :aggregate_failures do
      path = nil

      file_system.with_tempfile do |file|
        path = file.path

        expect(File.exist?(path)).to be true
      end

      expect(File.exist?(path)).to be false
    end
  end
end
