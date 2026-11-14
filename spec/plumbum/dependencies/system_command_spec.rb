# frozen_string_literal: true

require 'plumbum/dependencies/system_command'

RSpec.describe Plumbum::Dependencies::SystemCommand do
  subject(:system_command) { described_class.new }

  describe '::CapturedOutput' do
    subject(:captured) do
      described_class::CapturedOutput.new(error:, output:, status:)
    end

    let(:error)  { '[WARNING] Death Blossom is a weapon of last resort.' }
    let(:output) { 'Greetings, starfighter!' }
    let(:status) { instance_double(Process::Status, success?: true) }

    describe '#error' do
      include_examples 'should define reader', :error, -> { error }
    end

    describe '#output' do
      include_examples 'should define reader', :output, -> { output }
    end

    describe '#status' do
      include_examples 'should define reader', :status, -> { status }
    end

    describe '#success?' do
      include_examples 'should define predicate', :success?

      context 'when initialized with a failing status' do
        let(:status) { instance_double(Process::Status, success?: false) }

        it { expect(captured.success?).to be false }
      end

      context 'when initialized with a passing status' do
        let(:status) { instance_double(Process::Status, success?: true) }

        it { expect(captured.success?).to be true }
      end
    end
  end

  describe '#capture' do
    deferred_examples 'should call the system command' do
      it 'should delegate the command to Open3' do
        system_command.capture(command, arguments:, environment:, options:)

        expect(Open3).to have_received(:capture3).with(expected_command)
      end
    end

    let(:command)     { 'greet' }
    let(:arguments)   { nil }
    let(:environment) { nil }
    let(:options)     { nil }
    let(:error)       { '[WARNING] Death Blossom is a weapon of last resort.' }
    let(:output)      { 'Greetings, starfighter!' }
    let(:status) do
      instance_double(Process::Status, exitstatus: 0, success?: true)
    end
    let(:expected_command) do
      'greet'
    end
    let(:expected_value) do
      described_class::CapturedOutput.new(error:, output:, status:)
    end

    before(:example) do
      allow(Open3).to receive(:capture3).and_return([output, error, status])
    end

    it 'should define the method' do
      expect(system_command)
        .to respond_to(:capture)
        .with(1).argument
        .and_keywords(:arguments, :environment, :options)
    end

    include_deferred 'should call the system command'

    it 'should return a passing result' do
      expect(system_command.capture(command))
        .to be_a_passing_result
        .with_value(expected_value)
    end

    context 'when the process returns a failing result' do
      let(:expected_error) do
        Plumbum::Errors::SystemCommandFailure.new(
          command:     expected_command,
          details:     error,
          exit_status: status.exitstatus
        )
      end
      let(:status) do
        instance_double(Process::Status, exitstatus: 99, success?: false)
      end

      it 'should return a failing result' do
        expect(system_command.capture(command))
          .to be_a_failing_result
          .with_value(expected_value)
          .and_error(expected_error)
      end
    end

    describe 'with arguments: nil' do
      let(:arguments) { nil }

      include_deferred 'should call the system command'
    end

    describe 'with arguments: an empty Array' do
      let(:arguments) { [] }

      include_deferred 'should call the system command'
    end

    describe 'with arguments: raw values' do
      let(:arguments) { %w[path/to/file path/to/other] }
      let(:expected_command) do
        "#{super()} path/to/file path/to/other"
      end

      include_deferred 'should call the system command'
    end

    describe 'with arguments: single-character flags' do
      let(:arguments) { %w[-b -w] }
      let(:expected_command) do
        "#{super()} -b -w"
      end

      include_deferred 'should call the system command'
    end

    describe 'with arguments: multi-character flags' do
      let(:arguments) { %w[--example-flag --other-flag] }
      let(:expected_command) do
        "#{super()} --example-flag --other-flag"
      end

      include_deferred 'should call the system command'
    end

    describe 'with arguments: mixed values' do
      let(:arguments) { %w[path/to/file -b -w --example-flag] }
      let(:expected_command) do
        "#{super()} path/to/file -b -w --example-flag"
      end

      include_deferred 'should call the system command'
    end

    describe 'with environment: nil' do
      let(:environment) { nil }

      include_deferred 'should call the system command'
    end

    describe 'with environment: an empty Hash' do
      let(:environment) { {} }

      include_deferred 'should call the system command'
    end

    describe 'with environment: a non-empty Hash' do
      let(:environment) do
        {
          some_env:   'value',
          AnotherEnv: 'another value',
          MORE_ENV:   3,
          NOT_HERE:   nil
        }
      end
      let(:expected_command) do
        %(SOME_ENV="value" ANOTHER_ENV="another value" MORE_ENV=3 #{super()})
      end

      include_deferred 'should call the system command'
    end

    describe 'with options: nil' do
      let(:options) { nil }

      include_deferred 'should call the system command'
    end

    describe 'with options: an empty Hash' do
      let(:options) { {} }

      include_deferred 'should call the system command'
    end

    describe 'with options: a non-empty Hash' do
      let(:options) do
        {
          'k'        => 'v',
          'key'      => 'string value',
          'missing'  => nil,
          '-i'       => 1,
          '--secret' => '12345'
        }
      end
      let(:expected_command) do
        %(#{super()} -k="v" --key="string value" -i=1 --secret="12345")
      end

      include_deferred 'should call the system command'
    end

    describe 'with multiple parameters' do
      let(:arguments)   { 'path/to/file --option=value --option=other' }
      let(:environment) { { secret_key: 12_345 } }
      let(:options)     { { k: 'v', key: 'value' } }
      let(:expected_command) do
        %(SECRET_KEY=12345 #{super()} path/to/file --option=value ) \
          '--option=other -k="v" --key="value"'
      end

      include_deferred 'should call the system command'
    end
  end

  describe '#spawn' do
    deferred_examples 'should call the system command' do
      it 'should delegate the command to Process#spawn' do
        system_command.spawn(command, arguments:, environment:, options:)

        expect(Process).to have_received(:spawn).with(expected_command)
      end

      it 'should wait for the spawned process' do
        system_command.spawn(command, arguments:, environment:, options:)

        expect(Process).to have_received(:wait2).with(pid)
      end
    end

    let(:command)     { 'greet' }
    let(:arguments)   { nil }
    let(:environment) { nil }
    let(:options)     { nil }
    let(:pid)         { 15_151 }
    let(:status) do
      instance_double(Process::Status, exitstatus: 0, success?: true)
    end
    let(:expected_command) do
      'greet'
    end

    before(:example) do
      allow(Process).to receive_messages(
        spawn: pid,
        wait2: [pid, status]
      )
    end

    include_deferred 'should call the system command'

    it 'should return a passing result' do
      expect(system_command.spawn(command))
        .to be_a_passing_result
        .with_value(nil)
    end

    context 'when the process returns a failing result' do
      let(:expected_error) do
        Plumbum::Errors::SystemCommandFailure.new(
          command:     expected_command,
          exit_status: status.exitstatus
        )
      end
      let(:status) do
        instance_double(Process::Status, exitstatus: 99, success?: false)
      end

      it 'should return a failing result' do
        expect(system_command.spawn(command))
          .to be_a_failing_result
          .with_value(nil)
          .and_error(expected_error)
      end
    end

    describe 'with arguments: nil' do
      let(:arguments) { nil }

      include_deferred 'should call the system command'
    end

    describe 'with arguments: an empty Array' do
      let(:arguments) { [] }

      include_deferred 'should call the system command'
    end

    describe 'with arguments: raw values' do
      let(:arguments) { %w[path/to/file path/to/other] }
      let(:expected_command) do
        "#{super()} path/to/file path/to/other"
      end

      include_deferred 'should call the system command'
    end

    describe 'with arguments: single-character flags' do
      let(:arguments) { %w[-b -w] }
      let(:expected_command) do
        "#{super()} -b -w"
      end

      include_deferred 'should call the system command'
    end

    describe 'with arguments: multi-character flags' do
      let(:arguments) { %w[--example-flag --other-flag] }
      let(:expected_command) do
        "#{super()} --example-flag --other-flag"
      end

      include_deferred 'should call the system command'
    end

    describe 'with arguments: mixed values' do
      let(:arguments) { %w[path/to/file -b -w --example-flag] }
      let(:expected_command) do
        "#{super()} path/to/file -b -w --example-flag"
      end

      include_deferred 'should call the system command'
    end

    describe 'with environment: nil' do
      let(:environment) { nil }

      include_deferred 'should call the system command'
    end

    describe 'with environment: an empty Hash' do
      let(:environment) { {} }

      include_deferred 'should call the system command'
    end

    describe 'with environment: a non-empty Hash' do
      let(:environment) do
        {
          some_env:   'value',
          AnotherEnv: 'another value',
          MORE_ENV:   3,
          NOT_HERE:   nil
        }
      end
      let(:expected_command) do
        %(SOME_ENV="value" ANOTHER_ENV="another value" MORE_ENV=3 #{super()})
      end

      include_deferred 'should call the system command'
    end

    describe 'with options: nil' do
      let(:options) { nil }

      include_deferred 'should call the system command'
    end

    describe 'with options: an empty Hash' do
      let(:options) { {} }

      include_deferred 'should call the system command'
    end

    describe 'with options: a non-empty Hash' do
      let(:options) do
        {
          'k'        => 'v',
          'key'      => 'string value',
          'missing'  => nil,
          '-i'       => 1,
          '--secret' => '12345'
        }
      end
      let(:expected_command) do
        %(#{super()} -k="v" --key="string value" -i=1 --secret="12345")
      end

      include_deferred 'should call the system command'
    end

    describe 'with multiple parameters' do
      let(:arguments)   { 'path/to/file --option=value --option=other' }
      let(:environment) { { secret_key: 12_345 } }
      let(:options)     { { k: 'v', key: 'value' } }
      let(:expected_command) do
        %(SECRET_KEY=12345 #{super()} path/to/file --option=value ) \
          '--option=other -k="v" --key="value"'
      end

      include_deferred 'should call the system command'
    end
  end
end
