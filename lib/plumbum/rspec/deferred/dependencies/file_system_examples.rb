# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'plumbum/rspec/deferred/dependencies'

module Plumbum::RSpec::Deferred::Dependencies
  # Deferred examples for testing the FileSystem dependency.
  module FileSystemExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    define_method :absolute_path? do |path|
      path.start_with?('/')
    end

    define_method :qualified_path? do |path|
      path.start_with?('*')
    end

    deferred_context 'with fixture files and directories' do
      let(:fixtures_path) do
        defined?(super()) ? super() : '.'
      end
      let(:fixtures) do
        {
          'root_dir'      => {
            'child_dir'      => {},
            'child_file.txt' => 'Contents of root_dir/child_file.txt'
          },
          'root_file.txt' => 'Contents of root_file.txt'
        }
      end
      let(:flattened_fixture_names) do
        [
          'root_dir',
          'root_dir/child_dir',
          'root_dir/child_file.txt',
          'root_file.txt'
        ]
      end

      define_method :read_fixture do |path|
        return super(path) if defined?(super(path))

        fixtures.dig(*path.split(File::SEPARATOR))
      end
    end

    deferred_examples 'should handle a directory when a file is expected' \
    do |path_parameter = 'path', &block|
      context "when the #{path_parameter.to_s.tr('_', ' ')} is a directory" do
        let(path_parameter) do
          if absolute_path?(super())
            absolute_directory_path
          elsif qualified_path?(super())
            qualified_directory_path
          else
            relative_directory_path
          end
        end
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::FileIsADirectoryError
        end
        let(:error_message) do
          "#{error_reason} - file is a directory"
        end

        it 'should raise an exception' do
          expect { call_method }.to raise_error(error_class, error_message)
        end

        instance_exec(&block) if block
      end
    end

    deferred_examples 'should handle a file that already exists' \
    do |path_parameter = 'path', &block|
      context "when the #{path_parameter.to_s.tr('_', ' ')} is a file" do
        let(path_parameter) do
          if absolute_path?(super())
            absolute_file_path
          elsif qualified_path?(super())
            qualified_file_path
          else
            relative_file_path
          end
        end
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::FileAlreadyExistsError
        end
        let(:error_message) do
          "#{error_reason} - file already exists"
        end

        it 'should raise an exception' do
          expect { call_method }.to raise_error(error_class, error_message)
        end

        instance_exec(&block) if block
      end
    end

    deferred_examples 'should handle a file when a directory is expected' \
    do |path_parameter = 'path', &block|
      context "when the #{path_parameter.to_s.tr('_', ' ')} is a file" do
        let(path_parameter) do
          if absolute_path?(super())
            absolute_file_path
          elsif qualified_path?(super())
            qualified_file_path
          else
            relative_file_path
          end
        end
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::DirectoryIsAFileError
        end
        let(:error_message) do
          "#{error_reason} - directory is a file"
        end

        it 'should raise an exception' do
          expect { call_method }.to raise_error(error_class, error_message)
        end

        instance_exec(&block) if block
      end
    end

    deferred_examples 'should handle a path that includes a file' \
    do |path_parameter = 'path', &block|
      context "when the #{path_parameter.to_s.tr('_', ' ')} includes a file" do
        let(path_parameter) do
          dirname =
            if absolute_path?(super())
              absolute_file_path
            elsif qualified_path?(super())
              qualified_file_path
            else
              relative_file_path
            end

          File.join(dirname, File.basename(super()))
        end
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::DirectoryIsAFileError
        end
        let(:error_message) do
          "#{error_reason} - directory is a file"
        end

        it 'should raise an exception' do
          expect { call_method }.to raise_error(error_class, error_message)
        end

        instance_exec(&block) if block
      end
    end

    deferred_examples 'should handle a path with missing directory' \
    do |path_parameter = 'path', &block|
      parameter_name = path_parameter.to_s.tr('_', ' ')

      context "when the #{parameter_name} includes a missing directory" do
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::DirectoryNotFoundError
        end
        let(:error_message) do
          "#{error_reason} - directory not found"
        end

        context "when the #{parameter_name} is an absolute path" do
          let(path_parameter) do
            File.join(
              absolute_directory_path,
              'missing_directory',
              File.basename(super())
            )
          end

          it 'should raise an exception' do
            expect { call_method }.to raise_error(error_class, error_message)
          end

          instance_exec(&block) if block
        end

        context "when the #{parameter_name} is a qualified path" do
          let(path_parameter) do
            File.join(
              qualified_directory_path,
              'missing_directory',
              File.basename(super())
            )
          end

          it 'should raise an exception' do
            expect { call_method }.to raise_error(error_class, error_message)
          end

          instance_exec(&block) if block
        end

        context "when the #{parameter_name} is a relative path" do
          let(path_parameter) do
            File.join(
              relative_directory_path,
              'missing_directory',
              File.basename(super())
            )
          end

          it 'should raise an exception' do
            expect { call_method }.to raise_error(error_class, error_message)
          end

          instance_exec(&block) if block
        end
      end
    end

    deferred_examples 'should handle a path with missing file' \
    do |path_parameter = 'path', &block|
      parameter_name = path_parameter.to_s.tr('_', ' ')

      context "when the #{parameter_name} includes a missing file" do
        let(:error_class) do
          Plumbum::Dependencies::FileSystem::FileNotFoundError
        end
        let(:error_message) do
          "#{error_reason} - file not found"
        end

        context "when the #{parameter_name} is an absolute path" do
          let(path_parameter) { invalid_absolute_path }

          it 'should raise an exception' do
            expect { call_method }.to raise_error(error_class, error_message)
          end

          instance_exec(&block) if block
        end

        context "when the #{parameter_name} is a qualified path" do
          let(path_parameter) { invalid_qualified_path }

          it 'should raise an exception' do
            expect { call_method }.to raise_error(error_class, error_message)
          end

          instance_exec(&block) if block
        end

        context "when the #{parameter_name} is a relative path" do
          let(path_parameter) { invalid_relative_path }

          it 'should raise an exception' do
            expect { call_method }.to raise_error(error_class, error_message)
          end

          instance_exec(&block) if block
        end
      end
    end

    deferred_examples 'should validate the path' \
    do |path_parameter = 'path', &block|
      describe "with #{path_parameter.to_s.tr('_', ' ')}: nil" do
        let(path_parameter) { nil }
        let(:error_message) do
          tools
            .assertions
            .error_message_for('presence', as: path_parameter)
        end

        it 'should raise an exception' do
          expect { call_method }
            .to raise_error ArgumentError, error_message
        end

        instance_exec(&block) if block
      end

      describe "with #{path_parameter.to_s.tr('_', ' ')}: an Object" do
        let(path_parameter) { Object.new.freeze }
        let(:error_message) do
          "#{path_parameter} is not an instance of String"
        end

        it 'should raise an exception' do
          expect { call_method }
            .to raise_error ArgumentError, error_message
        end

        instance_exec(&block) if block
      end

      describe "with #{path_parameter.to_s.tr('_', ' ')}: an empty String" do
        let(path_parameter) { '' }
        let(:error_message) do
          tools
            .assertions
            .error_message_for('presence', as: path_parameter)
        end

        it 'should raise an exception' do
          expect { call_method }
            .to raise_error ArgumentError, error_message
        end

        instance_exec(&block) if block
      end
    end

    deferred_examples 'should validate the file or path' \
    do |path_parameter = 'path', &block|
      describe "with #{path_parameter.to_s.tr('_', ' ')}: nil" do
        let(path_parameter) { nil }
        let(:error_message) do
          tools
            .assertions
            .error_message_for('presence', as: path_parameter)
        end

        it 'should raise an exception' do
          expect { call_method }
            .to raise_error ArgumentError, error_message
        end

        instance_exec(&block) if block
      end

      describe "with #{path_parameter.to_s.tr('_', ' ')}: an Object" do
        let(path_parameter) { Object.new.freeze }
        let(:error_message) do
          "#{path_parameter} is not a String or IO stream"
        end

        it 'should raise an exception' do
          expect { call_method }
            .to raise_error ArgumentError, error_message
        end

        instance_exec(&block) if block
      end

      describe "with #{path_parameter.to_s.tr('_', ' ')}: an empty String" do
        let(path_parameter) { '' }
        let(:error_message) do
          tools
            .assertions
            .error_message_for('presence', as: path_parameter)
        end

        it 'should raise an exception' do
          expect { call_method }
            .to raise_error ArgumentError, error_message
        end

        instance_exec(&block) if block
      end
    end

    deferred_examples 'should implement the file_system dependency' do
      let(:invalid_absolute_path) do
        defined?(super()) ? super() : '/invalid-absolute-path'
      end
      let(:invalid_qualified_path) do
        defined?(super()) ? super() : '../invalid-qualified-path'
      end
      let(:invalid_relative_path) do
        defined?(super()) ? super() : 'invalid-relative-path'
      end

      describe '#copy_file' do
        deferred_context 'with destination_path: an absolute path' do
          let(:destination_path) do
            path     = absolute_file_path
            dirname  = File.dirname(path)
            basename = File.basename(path)
            extname  = File.extname(path)

            File.join(
              dirname,
              basename.sub(/#{extname}\z/, "_copy#{extname}")
            )
          end
          let(:path) { destination_path }
        end

        deferred_context 'with destination_path: a relative path' do
          let(:destination_path) do
            path     = relative_file_path
            dirname  = File.dirname(path)
            basename = File.basename(path)
            extname  = File.extname(path)

            File.join(
              dirname,
              basename.sub(/#{extname}\z/, "_copy#{extname}")
            )
          end
          let(:path) { destination_path }
        end

        deferred_context 'with destination_path: a qualified path' do
          let(:destination_path) do
            path =
              if defined?(root_path) && root_path
                "../#{root_path.split(File::SEPARATOR).last}/" \
                  "#{File.basename(qualified_file_path)}"
              else
                qualified_file_path
              end

            dirname  = File.dirname(path)
            basename = File.basename(path)
            extname  = File.extname(path)

            File.join(
              dirname,
              basename.sub(/#{extname}\z/, "_copy#{extname}")
            )
          end
          let(:path) { destination_path }
        end

        deferred_examples 'should not copy the file' do
          it 'should not copy the file' do
            expect { safe_copy_file }
              .not_to(change { subject.file?(destination_path) })
          end
        end

        deferred_examples 'should copy the file' do
          it 'should not change the source file', :aggregate_failures do
            copy_file

            expect(subject.file?(source_path)).to be true
            expect(subject.read_file(source_path)).to eq expected_contents
          end

          it 'should create the destination file', :aggregate_failures do
            copy_file

            expect(subject.file?(destination_path)).to be true
            expect(subject.read_file(destination_path))
              .to eq expected_contents
          end

          describe 'with a transform block' do
            let(:block)             { ->(data) { data.upcase } } # rubocop:disable Style/SymbolProc
            let(:expected_contents) { super().upcase }

            it 'should create the destination file', :aggregate_failures do
              copy_file

              expect(subject.file?(destination_path)).to be true
              expect(subject.read_file(destination_path))
                .to eq expected_contents
            end
          end
        end

        deferred_examples 'should copy the file to a valid destination' do
          include_deferred 'should copy the file'

          include_deferred 'should handle a directory when a file is expected',
            :destination_path \
          do
            include_deferred 'should not copy the file'
          end

          include_deferred 'should handle a file that already exists',
            :destination_path \
          do
            include_deferred 'should not copy the file'

            describe 'with force: true' do
              let(:copy_options) { super().merge(force: true) }

              include_deferred 'should copy the file'
            end
          end

          include_deferred 'should handle a path that includes a file',
            :destination_path \
          do
            include_deferred 'should not copy the file'
          end

          include_deferred 'should handle a path with missing directory',
            :destination_path \
          do
            include_deferred 'should not copy the file'
          end
        end

        let(:source_path)       { 'path/to/source.txt' }
        let(:destination_path)  { 'path/to/destination.txt' }
        let(:copy_options)      { {} }
        let(:block)             { nil }
        let(:expected_contents) { subject.read_file(source_path) }
        let(:error_reason)      { "unable to write file #{destination_path}" }

        define_method :copy_file do
          subject.copy_file(
            source_path,
            destination_path,
            **copy_options,
            &block
          )
        end
        alias_method :call_method, :copy_file

        define_method :safe_copy_file do
          copy_file
        rescue StandardError
          nil
        end

        include_deferred 'with valid file paths'

        it 'should define the method' do
          expect(subject)
            .to respond_to(:copy_file)
            .with(2).arguments
            .and_keywords(:force)
            .and_a_block
        end

        include_deferred 'should validate the path', :destination_path

        include_deferred 'should validate the path', :source_path

        include_deferred 'should handle a path with missing file',
          :source_path \
        do
          let(:error_reason) { "unable to read file #{source_path}" }

          include_deferred 'should not copy the file'
        end

        wrap_deferred 'with valid file paths' do
          describe 'with source_path: an absolute path' do
            let(:source_path) { absolute_file_path }

            include_deferred \
              'should handle a directory when a file is expected',
              :source_path \
            do
              let(:error_reason) { "unable to read file #{source_path}" }

              include_deferred 'should not copy the file'
            end

            # rubocop:disable RSpec/RepeatedExampleGroupBody
            wrap_deferred 'with destination_path: an absolute path' do
              include_deferred 'should copy the file to a valid destination'
            end

            wrap_deferred 'with destination_path: a qualified path' do
              include_deferred 'should copy the file to a valid destination'
            end

            wrap_deferred 'with destination_path: a relative path' do
              include_deferred 'should copy the file to a valid destination'
            end
            # rubocop:enable RSpec/RepeatedExampleGroupBody
          end

          describe 'with source_path: a qualified path to a file' do
            let(:source_path) { qualified_file_path }

            include_deferred \
              'should handle a directory when a file is expected',
              :source_path \
            do
              let(:error_reason) { "unable to read file #{source_path}" }

              include_deferred 'should not copy the file'
            end

            # rubocop:disable RSpec/RepeatedExampleGroupBody
            wrap_deferred 'with destination_path: an absolute path' do
              include_deferred 'should copy the file to a valid destination'
            end

            wrap_deferred 'with destination_path: a qualified path' do
              include_deferred 'should copy the file to a valid destination'
            end

            wrap_deferred 'with destination_path: a relative path' do
              include_deferred 'should copy the file to a valid destination'
            end
            # rubocop:enable RSpec/RepeatedExampleGroupBody
          end

          describe 'with source_path: a relative path' do
            let(:source_path) { relative_file_path }

            include_deferred \
              'should handle a directory when a file is expected',
              :source_path \
            do
              let(:error_reason) { "unable to read file #{source_path}" }

              include_deferred 'should not copy the file'
            end

            # rubocop:disable RSpec/RepeatedExampleGroupBody
            wrap_deferred 'with destination_path: an absolute path' do
              include_deferred 'should copy the file to a valid destination'
            end

            wrap_deferred 'with destination_path: a qualified path' do
              include_deferred 'should copy the file to a valid destination'
            end

            wrap_deferred 'with destination_path: a relative path' do
              include_deferred 'should copy the file to a valid destination'
            end
            # rubocop:enable RSpec/RepeatedExampleGroupBody
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with source_path: a qualified path' do
              let(:source_path) { qualified_file_path }

              include_deferred \
                'should handle a directory when a file is expected',
                :source_path \
              do
                let(:error_reason) { "unable to read file #{source_path}" }

                include_deferred 'should not copy the file'
              end

              # rubocop:disable RSpec/RepeatedExampleGroupBody
              wrap_deferred 'with destination_path: an absolute path' do
                include_deferred 'should copy the file to a valid destination'
              end

              wrap_deferred 'with destination_path: a qualified path' do
                include_deferred 'should copy the file to a valid destination'
              end

              wrap_deferred 'with destination_path: a relative path' do
                include_deferred 'should copy the file to a valid destination'
              end
              # rubocop:enable RSpec/RepeatedExampleGroupBody
            end

            describe 'with source_path: a relative path to a file' do
              let(:source_path) { relative_file_path }

              include_deferred \
                'should handle a directory when a file is expected',
                :source_path \
              do
                let(:error_reason) { "unable to read file #{source_path}" }

                include_deferred 'should not copy the file'
              end

              # rubocop:disable RSpec/RepeatedExampleGroupBody
              wrap_deferred 'with destination_path: an absolute path' do
                include_deferred 'should copy the file to a valid destination'
              end

              wrap_deferred 'with destination_path: a qualified path' do
                include_deferred 'should copy the file to a valid destination'
              end

              wrap_deferred 'with destination_path: a relative path' do
                include_deferred 'should copy the file to a valid destination'
              end
              # rubocop:enable RSpec/RepeatedExampleGroupBody
            end
          end
        end
      end

      describe '#create_directory' do
        deferred_examples 'should not create the directory' do
          it 'should not create the directory' do
            expect { safe_create_directory }.not_to(
              change { subject.directory?(path) }
            )
          end
        end

        deferred_examples 'should create the directory' do
          it { expect(create_directory).to be == path }

          it 'should create the directory' do
            expect { create_directory }.to(
              change { subject.directory?(path) }.to(be true)
            )
          end
        end

        deferred_examples 'should create the directory for a valid path' do
          include_deferred 'should create the directory'

          context 'when the directory already exists' do
            let(:path) do
              if absolute_path?(super())
                absolute_directory_path
              elsif qualified_path?(super())
                qualified_directory_path
              else
                relative_directory_path
              end
            end

            it { expect(create_directory).to be == path }

            include_deferred 'should not create the directory'
          end

          include_deferred 'should handle a file when a directory is expected' \
          do
            include_deferred 'should not create the directory'
          end

          include_deferred 'should handle a path with missing directory' \
          do
            include_deferred 'should not create the directory'

            describe 'with recursive: true' do
              let(:create_options) { super().merge(recursive: true) }

              include_deferred 'should create the directory'
            end
          end

          include_deferred 'should handle a path that includes a file' do
            include_deferred 'should not create the directory'
          end
        end

        let(:path)           { nil }
        let(:create_options) { {} }
        let(:error_reason)   { "unable to create directory #{path}" }

        define_method :create_directory do
          subject.create_directory(path, **create_options)
        end
        alias_method :call_method, :create_directory

        define_method :safe_create_directory do
          create_directory
        rescue StandardError
          nil
        end

        include_deferred 'with valid file paths'

        it 'should define the method' do
          expect(subject)
            .to respond_to(:create_directory)
            .with(1).argument
            .and_keywords(:recursive)
        end

        it 'should define the aliased method' do
          expect(subject)
            .to have_aliased_method(:create_directory)
            .as(:make_directory)
        end

        include_deferred 'should validate the path'

        describe 'with an absolute path' do
          let(:path) { File.join(absolute_directory_path, 'custom_dir') }

          include_deferred 'should create the directory for a valid path'
        end

        describe 'with a relative path' do
          let(:path) { File.join(relative_directory_path, 'custom_dir') }

          include_deferred 'should create the directory for a valid path'
        end

        describe 'with a qualified path' do
          let(:path) { File.join(qualified_directory_path, 'custom_dir') }

          include_deferred 'should create the directory for a valid path'
        end

        wrap_deferred 'when initialized with root_path: value' do
          describe 'with a relative path' do
            let(:path) { File.join(relative_directory_path, 'custom_dir') }

            include_deferred 'should create the directory for a valid path'
          end

          describe 'with a qualified path' do
            let(:path) { File.join(qualified_directory_path, 'custom_dir') }

            include_deferred 'should create the directory for a valid path'
          end
        end
      end

      describe '#delete_directory' do
        deferred_examples 'should not delete the directory' do
          it 'should not delete the directory' do
            expect { safe_delete_directory }.not_to(
              change { subject.directory?(path) }
            )
          end
        end

        deferred_examples 'should delete the directory' do
          it { expect(delete_directory).to be == path }

          it 'should delete the directory' do
            expect { delete_directory }.to(
              change { subject.directory?(path) }.to(be false)
            )
          end
        end

        deferred_examples 'should delete the directory for a valid path' do
          include_deferred 'should handle a path that includes a file' do
            include_deferred 'should not delete the directory'
          end

          include_deferred 'should handle a path with missing directory' do
            include_deferred 'should not delete the directory'
          end

          include_deferred 'should handle a path with missing directory' do
            include_deferred 'should not delete the directory'
          end

          context 'when the directory is empty' do
            let(:path) { File.join(super(), 'empty_dir') }

            include_deferred 'should delete the directory'
          end

          context 'when the directory contains empty directories' do
            let(:path) { File.join(super(), 'dir_with_directories') }
            let(:error_class) do
              Plumbum::Dependencies::FileSystem::DirectoryNotEmptyError
            end
            let(:error_message) do
              "#{error_reason} - directory is not empty"
            end

            it 'should raise an exception' do
              expect { delete_directory }
                .to raise_error(error_class, error_message)
            end

            include_deferred 'should not delete the directory'

            it 'should not change the directory contents' do
              expect { safe_delete_directory }
                .not_to(change { Dir[File.join(path, '**')] })
            end

            describe 'with force: true' do
              let(:delete_options) { super().merge(force: true) }

              include_deferred 'should delete the directory'
            end

            describe 'with recursive: true' do
              let(:delete_options) { super().merge(recursive: true) }

              include_deferred 'should delete the directory'
            end
          end

          context 'when the directory contains files' do
            let(:path) { File.join(super(), 'dir_with_files') }
            let(:error_class) do
              Plumbum::Dependencies::FileSystem::DirectoryNotEmptyError
            end
            let(:error_message) do
              "#{error_reason} - directory is not empty"
            end

            it 'should raise an exception' do
              expect { delete_directory }
                .to raise_error(error_class, error_message)
            end

            include_deferred 'should not delete the directory'

            it 'should not change the directory contents' do
              expect { safe_delete_directory }
                .not_to(change { Dir[File.join(path, '**')] })
            end

            describe 'with force: true' do
              let(:delete_options) { super().merge(force: true) }

              include_deferred 'should delete the directory'
            end

            describe 'with recursive: true' do
              let(:delete_options) { super().merge(recursive: true) }

              it 'should raise an exception' do
                expect { delete_directory }
                  .to raise_error(error_class, error_message)
              end

              include_deferred 'should not delete the directory'

              it 'should not change the directory contents' do
                expect { safe_delete_directory }
                  .not_to(change { Dir[File.join(path, '**')] })
              end
            end
          end
        end

        let(:path)           { nil }
        let(:delete_options) { {} }
        let(:error_reason)   { "unable to delete directory #{path}" }

        define_method :delete_directory do
          subject.delete_directory(path, **delete_options)
        end
        alias_method :call_method, :delete_directory

        define_method :safe_delete_directory do
          delete_directory
        rescue StandardError
          nil
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:delete_directory)
            .with(1).argument
            .and_keywords(:force, :recursive)
        end

        it 'should alias the method' do
          expect(subject)
            .to have_aliased_method(:delete_directory)
            .as(:remove_directory)
        end

        include_deferred 'should validate the path'

        wrap_deferred 'with valid file paths' do
          let(:directory_fixtures) do
            {
              'dir_with_directories' => {
                'empty_child'     => {},
                'non_empty_child' => {
                  'empty_grandchild' => {}
                }
              },
              'dir_with_files'       => {
                'empty_child'     => {},
                'non_empty_child' => {
                  'file.txt' => 'Existing contents.'
                }
              },
              'empty_dir'            => {}
            }
          end
          let(:fixtures) do
            root_path = defined?(self.root_path) ? self.root_path : Dir.pwd
            base_path = fixtures_path

            if base_path.start_with?('.')
              base_path = File.expand_path(File.join(root_path, base_path))
            end

            relative_path = absolute_directory_path[(1 + base_path.size)...]

            merge_fixtures(
              super(),
              *relative_path.split(File::SEPARATOR),
              directory_fixtures
            )
          end

          define_method :merge_fixtures do |fixtures, *path, value|
            return fixtures.merge(value) if path.empty?

            head, *tail = path

            fixtures.merge(head => merge_fixtures(fixtures[head], *tail, value))
          end

          describe 'with an absolute path' do
            let(:path) { absolute_directory_path }

            include_deferred 'should delete the directory for a valid path'
          end

          describe 'with a qualified path' do
            let(:path) { qualified_directory_path }

            include_deferred 'should delete the directory for a valid path'
          end

          describe 'with a relative path' do
            let(:path) { relative_directory_path }

            include_deferred 'should delete the directory for a valid path'
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with a relative path' do
              let(:path) { File.join(relative_directory_path) }

              include_deferred 'should delete the directory for a valid path'
            end

            describe 'with a qualified path' do
              let(:path) { File.join(qualified_directory_path) }

              include_deferred 'should delete the directory for a valid path'
            end
          end
        end
      end

      describe '#delete_file' do
        deferred_examples 'should not delete the file' do
          it 'should not delete the file' do
            expect { safe_delete_file }.not_to(
              change { subject.file?(path) }
            )
          end
        end

        deferred_examples 'should delete the file' do
          it { expect(delete_file).to be == path }

          it 'should delete the file' do
            expect { delete_file }.to(
              change { subject.file?(path) }.to(be false)
            )
          end
        end

        deferred_examples 'should delete the file for a valid path' do
          include_deferred 'should delete the file'

          include_deferred 'should handle a directory when a file is expected' \
          do
            include_deferred 'should not delete the file'
          end
        end

        let(:path)         { nil }
        let(:error_reason) { "unable to delete file #{path}" }

        define_method :delete_file do
          subject.delete_file(path)
        end
        alias_method :call_method, :delete_file

        define_method :safe_delete_file do
          delete_file
        rescue StandardError
          nil
        end

        it { expect(subject).to respond_to(:delete_file).with(1).argument }

        it 'should define the aliased method' do
          expect(subject).to have_aliased_method(:delete_file).as(:remove_file)
        end

        include_deferred 'should validate the path'

        include_deferred 'should handle a path with missing file'

        wrap_deferred 'with valid file paths' do
          describe 'with an absolute path' do
            let(:path) { absolute_file_path }

            include_deferred 'should delete the file for a valid path'
          end

          describe 'with a qualified path' do
            let(:path) { qualified_file_path }

            include_deferred 'should delete the file for a valid path'
          end

          describe 'with a relative path' do
            let(:path) { relative_file_path }

            include_deferred 'should delete the file for a valid path'
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with a qualified path' do
              let(:path) { qualified_file_path }

              include_deferred 'should delete the file for a valid path'
            end

            describe 'with a relative path' do
              let(:path) { relative_file_path }

              include_deferred 'should delete the file for a valid path'
            end
          end
        end
      end

      describe '#directory?' do
        define_method :check_directory do
          subject.directory?(path)
        end
        alias_method :call_method, :check_directory

        it 'should define the method' do
          expect(subject).to respond_to(:directory?).with(1).argument
        end

        it 'should define the aliased method' do
          expect(subject)
            .to have_aliased_method(:directory?)
            .as(:directory_exists?)
        end

        include_deferred 'should validate the path'

        describe 'with an invalid absolute path' do
          let(:path) { invalid_absolute_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with an invalid qualified path' do
          let(:path) { invalid_qualified_path }

          it { expect(subject.directory?(path)).to be false }
        end

        describe 'with an invalid relative path' do
          let(:path) { invalid_relative_path }

          it { expect(subject.directory?(path)).to be false }
        end

        wrap_deferred 'with valid file paths' do
          describe 'with an absolute path to a directory' do
            let(:path) { absolute_directory_path }

            it { expect(subject.directory?(path)).to be true }
          end

          describe 'with an absolute path to a file' do
            let(:path) { absolute_file_path }

            it { expect(subject.directory?(path)).to be false }
          end

          describe 'with a qualified path to a directory' do
            let(:path) { qualified_directory_path }

            it { expect(subject.directory?(path)).to be true }
          end

          describe 'with a qualified path to a file' do
            let(:path) { qualified_file_path }

            it { expect(subject.directory?(path)).to be false }
          end

          describe 'with a relative path to a directory' do
            let(:path) { relative_directory_path }

            it { expect(subject.directory?(path)).to be true }
          end

          describe 'with a relative path to a file' do
            let(:path) { relative_file_path }

            it { expect(subject.directory?(path)).to be false }
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with a qualified path to a directory' do
              let(:path) { qualified_directory_path }

              it { expect(subject.directory?(path)).to be true }
            end

            describe 'with a qualified path to a file' do
              let(:path) { qualified_file_path }

              it { expect(subject.directory?(path)).to be false }
            end

            describe 'with a relative path to a directory' do
              let(:path) { relative_directory_path }

              it { expect(subject.directory?(path)).to be true }
            end

            describe 'with a relative path to a file' do
              let(:path) { relative_file_path }

              it { expect(subject.directory?(path)).to be false }
            end
          end
        end
      end

      describe '#each_file' do
        deferred_examples 'should return or yield the matching file names' do
          describe 'without a block' do
            it { expect(subject.each_file(pattern)).to be_a Enumerator }

            it 'should return the matching file names' do
              expect(subject.each_file(pattern).to_a).to be == expected_files
            end
          end

          describe 'with a block' do
            it { expect(subject.each_file(pattern) { nil }).to be nil }

            it 'should yield the matching file names' do
              expect { |block| subject.each_file(pattern, &block) }.then \
              do |expectation|
                if expected_files.empty?
                  expectation.not_to(yield_control)
                else
                  expectation.to yield_successive_args(*expected_files)
                end
              end
            end
          end
        end

        let(:defined_files) { flattened_fixture_names }

        it 'should define the method' do
          expect(subject)
            .to respond_to(:each_file)
            .with(1).argument
            .and_a_block
        end

        wrap_deferred 'with valid file paths' do
          let(:expected_files) { defined_files }

          describe 'with a pattern that does not match any files' do
            let(:pattern)        { '*.xml' }
            let(:expected_files) { [] }

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a globbed pattern' do
            let(:pattern) { '*.txt' }
            let(:expected_files) do
              rxp = /\A\w+\.txt\z/

              defined_files.grep(rxp)
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a globbed pattern with fixed segments' do
            let(:pattern) { File.join('root_dir', '*.txt') }
            let(:expected_files) do
              rxp = %r{\Aroot_dir/\w+\.txt\z}

              defined_files.grep(rxp)
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a globbed pattern without extension filter' do
            let(:pattern) { '*' }
            let(:expected_files) do
              rxp = /\A\w+(\.\w+)?\z/

              defined_files.grep(rxp)
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a recursive globbed pattern' do
            let(:pattern) { File.join('**', '*.txt') }
            let(:expected_files) do
              rxp = /\.txt\z/

              defined_files.grep(rxp)
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a recursive globbed pattern with prefix' do
            let(:pattern) { File.join('root_dir', '**') }
            let(:expected_files) do
              rxp = %r{\Aroot_dir/}

              defined_files.grep(rxp)
            end

            include_deferred 'should return or yield the matching file names'
          end

          describe 'with a pattern that includes the root path' do
            let(:pattern) { File.join(subject.root_path, '*.txt') }
            let(:expected_files) do
              rxp = /\A\w+\.txt\z/

              defined_files
                .map do |path|
                  path = File.expand_path(File.join(fixtures_path, path))

                  next unless path.start_with?(subject.root_path)

                  path[(1 + subject.root_path.size)...]
                end # rubocop:disable Style/MultilineBlockChain
                .compact
                .grep(rxp)
                .map { |path| File.join(subject.root_path, path) }
            end

            include_deferred 'should return or yield the matching file names'

            wrap_deferred 'when initialized with root_path: value' do
              include_deferred 'should return or yield the matching file names'
            end
          end

          context 'when a matching file is added to the file system' do
            let(:pattern)         { '*.txt' }
            let(:added_file_path) { 'added_file.txt' }
            let(:expanded_added_path) do
              File.expand_path(File.join(fixtures_path, 'added_file.txt'))
            end
            let(:expected_files) do
              rxp = /\A\w+\.txt\z/

              defined_files
                .grep(rxp)
                .push(added_file_path)
                .sort
            end

            before(:example) do
              subject.each_file(pattern) { nil }

              subject.write_file(
                expanded_added_path,
                'This file was added in the test.'
              )
            end

            after(:example) do
              next unless subject.file?(expanded_added_path)

              subject.delete_file(expanded_added_path)
            end

            include_deferred 'should return or yield the matching file names'
          end
        end
      end

      describe '#file?' do
        define_method :check_file do
          subject.file?(path)
        end
        alias_method :call_method, :check_file

        it 'should define the method' do
          expect(subject).to respond_to(:file?).with(1).argument
        end

        it 'should define the aliased method' do
          expect(subject)
            .to have_aliased_method(:file?)
            .as(:file_exists?)
        end

        include_deferred 'should validate the path'

        describe 'with an invalid absolute path' do
          let(:path) { invalid_absolute_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with an invalid qualified path' do
          let(:path) { invalid_qualified_path }

          it { expect(subject.file?(path)).to be false }
        end

        describe 'with an invalid relative path' do
          let(:path) { invalid_relative_path }

          it { expect(subject.file?(path)).to be false }
        end

        wrap_deferred 'with valid file paths' do
          describe 'with an absolute path to a directory' do
            let(:path) { absolute_directory_path }

            it { expect(subject.file?(path)).to be false }
          end

          describe 'with an absolute path to a file' do
            let(:path) { absolute_file_path }

            it { expect(subject.file?(path)).to be true }
          end

          describe 'with a qualified path to a directory' do
            let(:path) { qualified_directory_path }

            it { expect(subject.file?(path)).to be false }
          end

          describe 'with a qualified path to a file' do
            let(:path) { qualified_file_path }

            it { expect(subject.file?(path)).to be true }
          end

          describe 'with a relative path to a directory' do
            let(:path) { relative_directory_path }

            it { expect(subject.file?(path)).to be false }
          end

          describe 'with a relative path to a file' do
            let(:path) { relative_file_path }

            it { expect(subject.file?(path)).to be true }
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with a qualified path to a directory' do
              let(:path) { qualified_directory_path }

              it { expect(subject.file?(path)).to be false }
            end

            describe 'with a qualified path to a file' do
              let(:path) { qualified_file_path }

              it { expect(subject.file?(path)).to be true }
            end

            describe 'with a relative path to a directory' do
              let(:path) { relative_directory_path }

              it { expect(subject.file?(path)).to be false }
            end

            describe 'with a relative path to a file' do
              let(:path) { relative_file_path }

              it { expect(subject.file?(path)).to be true }
            end
          end
        end
      end

      describe '#read_file' do
        deferred_examples 'should read the file' do
          it { expect(subject.read_file(file)).to be == expected_contents }
        end

        deferred_examples 'should read the file for a valid path' do
          include_deferred 'should read the file'

          include_deferred 'should handle a directory when a file is expected',
            :file
        end

        let(:expected_contents) do
          path = file

          unless path.start_with?('/')
            path = File.expand_path(File.join(subject.root_path, path))
          end

          path = path.sub(%r{\A#{File.expand_path(fixtures_path)}/?}, '')

          read_fixture(path)
        end
        let(:file)         { nil }
        let(:error_reason) { "unable to read file #{file}" }

        define_method :read_file do
          subject.read_file(file)
        end
        alias_method :call_method, :read_file

        define_method :safe_read_file do
          read_file
        rescue StandardError
          nil
        end

        it { expect(subject).to respond_to(:read_file).with(1).argument }

        it 'should define the aliased method' do
          expect(subject).to have_aliased_method(:read_file).as(:read)
        end

        include_deferred 'should validate the file or path', :file

        describe 'with an IO stream' do
          let(:stream) { StringIO.new('Greetings, programs!') }

          it { expect(subject.read_file(stream)).to be == stream.string }
        end

        include_deferred 'should handle a path with missing file', :file

        wrap_deferred 'with valid file paths' do
          describe 'with an absolute path' do
            let(:file) { absolute_file_path }

            include_deferred 'should read the file for a valid path'
          end

          describe 'with a qualified path' do
            let(:file) { qualified_file_path }

            include_deferred 'should read the file for a valid path'
          end

          describe 'with a relative path' do
            let(:file) { relative_file_path }

            include_deferred 'should read the file for a valid path'
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with a qualified path' do
              let(:file) { qualified_file_path }

              include_deferred 'should read the file for a valid path'
            end

            describe 'with a relative path' do
              let(:file) { relative_file_path }

              include_deferred 'should read the file for a valid path'
            end
          end
        end
      end

      describe '#root_path' do
        include_examples 'should define reader', :root_path, Dir.pwd

        wrap_deferred 'when initialized with root_path: value' do
          it { expect(subject.root_path).to be == root_path }
        end
      end

      describe '#with_tempfile' do
        let(:expected_tempfile) do
          respond_to(:read)
            .and(respond_to(:write)
            .and(respond_to(:path)))
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:with_tempfile)
            .with(0).arguments
            .and_a_block
        end

        it 'should yield the file object' do
          expect { |block| subject.with_tempfile(&block) }
            .to yield_with_args(expected_tempfile)
        end
      end

      describe '#write_file' do
        deferred_examples 'should not write the file' do
          it 'should not write the file', :aggregate_failures do
            existing_file     = subject.file?(file)
            existing_contents = subject.read_file(file) if existing_file

            expect { safe_write_file }.not_to(change { subject.file?(file) })

            next unless existing_file

            expect(subject.read_file(file)).to eq(existing_contents)
          end
        end

        deferred_examples 'should create the file' do
          it 'should create the file' do
            expect { write_file }.to(
              change { subject.file?(file) }.to(be true)
            )
          end
        end

        deferred_examples 'should write the data to the file' do
          it 'should write the data to the file' do
            write_file

            expect(subject.read_file(file)).to be == data
          end
        end

        deferred_examples 'should write the file for a valid path' do
          include_deferred 'should create the file'

          include_deferred 'should write the data to the file'

          include_deferred 'should handle a path with missing directory',
            :file \
          do
            include_deferred 'should not write the file'
          end

          include_deferred 'should handle a directory when a file is expected',
            :file \
          do
            include_deferred 'should not write the file'
          end

          context 'when the file already exists' do
            let(:file) do
              if absolute_path?(super())
                absolute_file_path
              elsif qualified_path?(super())
                qualified_file_path
              else
                relative_file_path
              end
            end

            include_deferred 'should write the data to the file'
          end

          include_deferred 'should handle a path that includes a file',
            :file \
          do
            include_deferred 'should not write the file'
          end

          include_deferred 'should handle a path with missing directory',
            :file \
          do
            include_deferred 'should not write the file'
          end
        end

        let(:file) { "#{SecureRandom.uuid}.txt" }
        let(:data) { "Greetings, programs!\n" }
        let(:error_reason) { "unable to write file #{file}" }

        define_method :write_file do
          subject.write_file(file, data)
        end
        alias_method :call_method, :write_file

        define_method :safe_write_file do
          write_file
        rescue StandardError
          nil
        end

        it { expect(subject).to respond_to(:write_file).with(2).arguments }

        it 'should define the aliased method' do
          expect(subject).to have_aliased_method(:write_file).as(:write)
        end

        include_deferred 'should validate the file or path', :file

        describe 'with data: nil' do
          let(:data)   { nil }
          let(:stream) { StringIO.new }

          it 'should not write to the stream' do
            expect { subject.write_file(stream, data) }
              .not_to change(stream, :string)
          end
        end

        describe 'with data: an Object' do
          let(:data)   { Object.new.freeze }
          let(:stream) { StringIO.new }

          it 'should write the object to the stream' do
            expect { subject.write_file(stream, data) }
              .to change(stream, :string)
              .to be == data.inspect
          end
        end

        describe 'with data: an empty String' do
          let(:data)   { '' }
          let(:stream) { StringIO.new }

          it 'should not write to the stream' do
            expect { subject.write_file(stream, data) }
              .not_to change(stream, :string)
          end
        end

        describe 'with file: an IO stream' do
          let(:stream) { StringIO.new }

          it 'should write the data to the stream' do
            expect { subject.write_file(stream, data) }
              .to change(stream, :string)
              .to be == data
          end
        end

        wrap_deferred 'with valid file paths' do
          describe 'with an absolute path' do
            let(:file) do
              File.join(absolute_directory_path, "#{SecureRandom.uuid}.txt")
            end

            include_deferred 'should write the file for a valid path'
          end

          describe 'with a qualified path' do
            let(:file) do
              File.join(qualified_directory_path, "#{SecureRandom.uuid}.txt")
            end

            include_deferred 'should write the file for a valid path'
          end

          describe 'with a relative path' do
            let(:file) do
              File.join(relative_directory_path, "#{SecureRandom.uuid}.txt")
            end

            include_deferred 'should write the file for a valid path'
          end

          wrap_deferred 'when initialized with root_path: value' do
            describe 'with a qualified path' do
              let(:file) do
                File.join(qualified_directory_path, "#{SecureRandom.uuid}.txt")
              end

              include_deferred 'should write the file for a valid path'
            end

            describe 'with a relative path' do
              let(:file) do
                File.join(relative_directory_path, "#{SecureRandom.uuid}.txt")
              end

              include_deferred 'should write the file for a valid path'
            end
          end
        end
      end
    end
  end
end
