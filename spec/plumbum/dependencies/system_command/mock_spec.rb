# frozen_string_literal: true

require 'plumbum/dependencies/system_command/mock'

RSpec.describe Plumbum::Dependencies::SystemCommand::Mock do
  subject(:mock_command) { described_class.new(captures:) }

  let(:captures) { {} }

  describe '::MockStatus' do
    subject(:status) { described_class::MockStatus.new(exitstatus:) }

    let(:exitstatus) { 0 }

    include_examples 'should define constant', :MockStatus, -> { be < Data }

    describe '#exitstatus' do
      include_examples 'should define reader', :exitstatus, -> { exitstatus }
    end

    describe '#success?' do
      include_examples 'should define predicate', :success?

      context 'when initialized with exitstatus: zero' do
        let(:exitstatus) { 0 }

        it { expect(status.success?).to be true }
      end

      context 'when initialized with exitstatus: a non-zero Integer' do
        let(:exitstatus) { 1 }

        it { expect(status.success?).to be false }
      end
    end
  end

  # rubocop:disable-next RSpec/MultipleMemoizedHelpers
  describe '#capture' do
    deferred_examples 'should capture the command' do
      it 'should return a passing result' do
        expect(
          mock_command.capture(command, arguments:, environment:, options:)
        )
          .to be_a_result
          .with_status(status.success? ? :success : :failure)
          .and_value(expected_value)
          .and_error(expected_error)
      end

      it 'should record the command', :aggregate_failures do
        expect do
          mock_command.capture(command, arguments:, environment:, options:)
        end
          .to(change { mock_command.recorded_commands.count }.by(1))

        expect(mock_command.recorded_commands.last).to be == expected_command
      end
    end

    let(:command)     { 'greet' }
    let(:arguments)   { nil }
    let(:environment) { nil }
    let(:options)     { nil }
    let(:error)       { '' }
    let(:output)      { '' }
    let(:exitstatus)  { 0 }
    let(:status)      { described_class::MockStatus.new(exitstatus:) }
    let(:expected_command) do
      command
    end
    let(:expected_value) do
      Plumbum::Dependencies::SystemCommand::CapturedOutput
        .new(error:, output:, status:)
    end
    let(:expected_error) { nil }

    it 'should define the method' do
      expect(mock_command)
        .to respond_to(:capture)
        .with(1).argument
        .and_keywords(:arguments, :environment, :options)
    end

    include_deferred 'should capture the command'

    describe 'with command parameters' do
      let(:arguments)   { 'starfighter' }
      let(:environment) { { recruiter: 'Star League' } }
      let(:options)     { { defend: 'frontier' } }
      let(:expected_command) do
        %(RECRUITER="Star League" #{super()} starfighter --defend="frontier")
      end

      include_deferred 'should capture the command'
    end

    context 'when initialized with captures: value' do
      let(:captures) { { 'boast' => ['', 'You should be more modest!', 1] } }

      include_deferred 'should capture the command'

      context 'when the command matches a capture array' do
        let(:output) { 'Greetings, programs!' }
        let(:captures) do
          super().merge(command => [output, '', 0])
        end

        include_deferred 'should capture the command'
      end

      context 'when the command matches a capture proc' do
        let(:command) { 'ask' }
        let(:captures) do
          capture = lambda do |arguments: nil, **|
            if arguments&.any? { |argument| argument.include?('please') }
              ['Since you asked nicely...', '', 0]
            else
              ['', 'You forgot the magic word!', 1]
            end
          end

          super().merge(command => capture)
        end
        let(:output)     { '' }
        let(:error)      { 'You forgot the magic word!' }
        let(:exitstatus) { 1 }
        let(:expected_error) do
          Plumbum::Errors::SystemCommandFailure.new(
            command:     expected_command,
            details:     error,
            exit_status: status.exitstatus
          )
        end

        include_deferred 'should capture the command'

        describe 'with command parameters' do
          let(:arguments)      { %w[--pretty-please] }
          let(:output)         { 'Since you asked nicely...' }
          let(:error)          { '' }
          let(:exitstatus)     { 0 }
          let(:expected_error) { nil }
          let(:expected_command) do
            "#{super()} --pretty-please"
          end

          include_deferred 'should capture the command'
        end
      end
    end
  end

  describe '#recorded_commands' do
    include_examples 'should define reader', :recorded_commands, []
  end

  describe '#spawn' do
    deferred_examples 'should capture the command' do
      it 'should return a passing result' do
        expect(
          mock_command.spawn(command, arguments:, environment:, options:)
        )
          .to be_a_result
          .with_status(status.success? ? :success : :failure)
          .and_value(nil)
          .and_error(expected_error)
      end

      it 'should record the command', :aggregate_failures do
        expect do
          mock_command.spawn(command, arguments:, environment:, options:)
        end
          .to(change { mock_command.recorded_commands.count }.by(1))

        expect(mock_command.recorded_commands.last).to be == expected_command
      end
    end

    let(:command)     { 'greet' }
    let(:arguments)   { nil }
    let(:environment) { nil }
    let(:options)     { nil }
    let(:exitstatus)  { 0 }
    let(:status)      { described_class::MockStatus.new(exitstatus:) }
    let(:expected_command) do
      command
    end
    let(:expected_error) { nil }

    it 'should define the method' do
      expect(mock_command)
        .to respond_to(:spawn)
        .with(1).argument
        .and_keywords(:arguments, :environment, :options)
    end

    include_deferred 'should capture the command'

    describe 'with command parameters' do
      let(:arguments)   { 'starfighter' }
      let(:environment) { { recruiter: 'Star League' } }
      let(:options)     { { defend: 'frontier' } }
      let(:expected_command) do
        %(RECRUITER="Star League" #{super()} starfighter --defend="frontier")
      end

      include_deferred 'should capture the command'
    end

    context 'when initialized with captures: value' do
      let(:captures) { { 'boast' => ['', 'You should be more modest!', 1] } }

      include_deferred 'should capture the command'

      context 'when the command matches a capture array' do
        let(:output) { 'Greetings, programs!' }
        let(:captures) do
          super().merge(command => [output, '', 0])
        end

        include_deferred 'should capture the command'
      end

      context 'when the command matches a capture proc' do
        let(:command) { 'ask' }
        let(:captures) do
          capture = lambda do |arguments: nil, **|
            if arguments&.any? { |argument| argument.include?('please') }
              ['Since you asked nicely...', '', 0]
            else
              ['', 'You forgot the magic word!', 1]
            end
          end

          super().merge(command => capture)
        end
        let(:exitstatus) { 1 }
        let(:expected_error) do
          Plumbum::Errors::SystemCommandFailure.new(
            command:     expected_command,
            exit_status: status.exitstatus
          )
        end

        include_deferred 'should capture the command'

        describe 'with command parameters' do
          let(:arguments)      { %w[--pretty-please] }
          let(:exitstatus)     { 0 }
          let(:expected_error) { nil }
          let(:expected_command) do
            "#{super()} --pretty-please"
          end

          include_deferred 'should capture the command'
        end
      end
    end
  end
end
