# frozen_string_literal: true

require 'plumbum/errors/system_command_failure'

RSpec.describe Plumbum::Errors::SystemCommandFailure do
  subject(:error) { described_class.new(command:, details:, exit_status:) }

  let(:command)     { 'echo "Greetings, programs!"' }
  let(:details)     { 'END OF LINE' }
  let(:exit_status) { 99 }

  describe '::TYPE' do
    include_examples 'should define immutable constant',
      :TYPE,
      'cuprum.cli.errors.system_command_failure'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:command, :details, :exit_status)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'command'     => command,
          'details'     => details,
          'exit_status' => exit_status
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#command' do
    include_examples 'should define reader', :command, -> { command }
  end

  describe '#details' do
    include_examples 'should define reader', :details, -> { details }
  end

  describe '#exit_status' do
    include_examples 'should define reader', :exit_status, -> { exit_status }
  end

  describe '#message' do
    let(:expected) do
      %(system command failed with exit status #{exit_status} - "#{command}")
    end

    include_examples 'should have reader', :message, -> { be == expected }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
