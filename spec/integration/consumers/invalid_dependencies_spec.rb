# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::Consumer do
  subject(:consumer) { described_class.new }

  let(:described_class) { Spec::Consumer }
  let(:config) do
    {
      users: [
        Spec::User.new(name: 'Alan Bradley', role: 'user'),
        Spec::User.new(name: 'Ed Dillinger', role: 'admin')
      ]
    }
  end

  example_constant 'Spec::User' do
    Data.define(:name, :role)
  end

  example_constant 'Spec::ConfigProvider' do
    Plumbum::OneProvider.new(:config, value: config)
  end

  example_class 'Spec::Consumer' do |klass|
    klass.include Plumbum::Consumer # rubocop:disable RSpec/DescribedClass

    klass.provider Spec::ConfigProvider

    klass.dependency :secrets

    # Dependency exists but key is missing from path.
    klass.dependency 'config.admins', as: :admins

    # Dependency exists but method is missing from path.
    klass.dependency 'config.users.first.admin?', as: :first_user_admin?

    klass.dependency 'config.users.first.role', as: :first_user_role
  end

  describe '#admins' do
    let(:error_message) do
      'key not found: "admins"'
    end

    it 'should raise an exception' do
      expect { consumer.admins }
        .to raise_error Plumbum::Errors::MissingDependencyError, error_message
    end
  end

  describe '#first_user_admin?' do
    let(:error_message) do
      'undefined method "admin?" for an instance of Spec::User'
    end

    it 'should raise an exception' do
      expect { consumer.first_user_admin? }
        .to raise_error Plumbum::Errors::MissingDependencyError, error_message
    end
  end

  describe '#first_user_role' do
    it { expect(consumer.first_user_role).to be == 'user' }
  end

  describe '#secrets' do
    let(:error_message) do
      'dependency not found with key :secrets'
    end

    it 'should raise an exception' do
      expect { consumer.secrets }
        .to raise_error Plumbum::Errors::MissingDependencyError, error_message
    end
  end
end
