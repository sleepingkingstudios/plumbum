# frozen_string_literal: true

require 'stringio'

require 'plumbum/dependencies/standard_io'

RSpec.describe Plumbum::Dependencies::StandardIo do
  subject(:standard_io) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:input_stream, :error_stream, :output_stream)
    end
  end

  describe '#color' do
    let(:text)       { 'Greetings, starfighter!' }
    let(:color_code) { 0 }
    let(:expected)   { "\e[#{color_code}m#{text}\e[0m" }

    it { expect(standard_io).to respond_to(:color).with(2).arguments }

    describe 'with color name: an invalid value' do
      let(:color) { 'octarine' }
      let(:error_message) do
        {}.fetch(color)
      rescue KeyError => exception
        exception.message
      end

      it 'should raise an exception' do
        expect { standard_io.color(text, color) }
          .to raise_error KeyError, error_message
      end
    end

    describe 'with color name: black' do
      let(:color_code) { 0 }

      it { expect(standard_io.color(text, 'black')).to be == expected }
    end

    describe 'with color name: blue' do
      let(:color_code) { 34 }

      it { expect(standard_io.color(text, 'blue')).to be == expected }
    end

    describe 'with color name: green' do
      let(:color_code) { 32 }

      it { expect(standard_io.color(text, 'green')).to be == expected }
    end

    describe 'with color name: purple' do
      let(:color_code) { 35 }

      it { expect(standard_io.color(text, 'purple')).to be == expected }
    end

    describe 'with color name: red' do
      let(:color_code) { 31 }

      it { expect(standard_io.color(text, 'red')).to be == expected }
    end

    describe 'with color name: yellow' do
      let(:color_code) { 33 }

      it { expect(standard_io.color(text, 'yellow')).to be == expected }
    end
  end

  describe '#error_stream' do
    include_examples 'should define private reader',
      :error_stream,
      -> { $stderr }

    context 'when initialized with error_stream: a Proc' do
      let(:error_stream)        { StringIO.new }
      let(:lazy_stream)         { -> { error_stream } }
      let(:constructor_options) { super().merge(error_stream: lazy_stream) }

      it { expect(standard_io.send(:error_stream)).to be error_stream }
    end

    context 'when initialized with error_stream: value' do
      let(:error_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(error_stream:) }

      it { expect(standard_io.send(:error_stream)).to be error_stream }
    end
  end

  describe '#input_stream' do
    include_examples 'should define private reader',
      :input_stream,
      -> { $stdin }

    context 'when initialized with input_stream: a Proc' do
      let(:input_stream)        { StringIO.new }
      let(:lazy_stream)         { -> { input_stream } }
      let(:constructor_options) { super().merge(input_stream: lazy_stream) }

      it { expect(standard_io.send(:input_stream)).to be input_stream }
    end

    context 'when initialized with input_stream: value' do
      let(:input_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(input_stream:) }

      it { expect(standard_io.send(:input_stream)).to be input_stream }
    end
  end

  describe '#output_stream' do
    include_examples 'should define private reader',
      :output_stream,
      -> { $stdout }

    context 'when initialized with output_stream: a Proc' do
      let(:output_stream)       { StringIO.new }
      let(:lazy_stream)         { -> { output_stream } }
      let(:constructor_options) { super().merge(output_stream: lazy_stream) }

      it { expect(standard_io.send(:output_stream)).to be output_stream }
    end

    context 'when initialized with output_stream: value' do
      let(:output_stream)       { StringIO.new }
      let(:constructor_options) { super().merge(output_stream:) }

      it { expect(standard_io.send(:output_stream)).to be output_stream }
    end
  end

  describe '#read_input' do
    let(:raw_input) { "\n" }

    before(:example) do
      allow($stdin).to receive(:gets).and_return(raw_input)
    end

    it { expect(standard_io).to respond_to(:read_input).with(0).arguments }

    it { expect(standard_io.read_input).to be == raw_input }

    context 'when the input is a non-empty String' do
      let(:raw_input) { "Alan Bradley\n" }

      it { expect(standard_io.read_input).to be == raw_input }
    end

    context 'when initialized with input_stream: value' do
      let(:input_stream)        { StringIO.new(raw_input) }
      let(:constructor_options) { super().merge(input_stream:) }

      before(:example) do
        allow($stdin).to receive(:gets).and_call_original
      end

      it { expect(standard_io.read_input).to be == raw_input }

      context 'when the input is a non-empty String' do
        let(:raw_input) { "Alan Bradley\n" }

        it { expect(standard_io.read_input).to be == raw_input }
      end
    end
  end

  describe '#write_error' do
    it 'should define the method' do
      expect(standard_io)
        .to respond_to(:write_error)
        .with(0..1).arguments
        .and_keywords(:newline)
    end

    describe 'with no parameters' do
      it { expect { standard_io.write_error }.to output("\n").to_stderr }
    end

    describe 'with no message and newline: false' do
      it 'should not write to STDERR' do
        expect { standard_io.write_error(newline: false) }
          .not_to output
          .to_stderr
      end
    end

    describe 'with no message and newline: true' do
      it 'should write a newline to STDERR' do
        expect { standard_io.write_error(newline: true) }
          .to output("\n")
          .to_stderr
      end
    end

    describe 'with an empty String' do
      let(:message) { '' }

      it 'should write a newline to STDERR' do
        expect { standard_io.write_error(message) }
          .to output("\n")
          .to_stderr
      end

      describe 'with newline: false' do
        it 'should not write to STDERR' do
          expect { standard_io.write_error(message, newline: false) }
            .not_to output
            .to_stderr
        end
      end

      describe 'with newline: true' do
        it 'should write a newline to STDERR' do
          expect { standard_io.write_error(message, newline: true) }
            .to output("\n")
            .to_stderr
        end
      end
    end

    describe 'with a non-empty String' do
      let(:message) { 'Greetings, programs!' }

      it 'should write the message to STDERR with a newline' do
        expect { standard_io.write_error(message) }
          .to output("#{message}\n")
          .to_stderr
      end

      describe 'with newline: false' do
        it 'should write the message to STDERR' do
          expect { standard_io.write_error(message, newline: false) }
            .to output(message)
            .to_stderr
        end
      end

      describe 'with newline: true' do
        it 'should write the message to STDERR with a newline' do
          expect { standard_io.write_error(message, newline: true) }
            .to output("#{message}\n")
            .to_stderr
        end
      end
    end

    describe 'with a String ending with a newline' do
      let(:message) { "Greetings, programs!\n" }

      it 'should write the message to STDERR' do
        expect { standard_io.write_error(message) }
          .to output(message)
          .to_stderr
      end

      describe 'with newline: false' do
        it 'should write the message to STDERR' do
          expect { standard_io.write_error(message, newline: false) }
            .to output(message)
            .to_stderr
        end
      end

      describe 'with newline: true' do
        it 'should write the message to STDERR' do
          expect { standard_io.write_error(message, newline: true) }
            .to output(message)
            .to_stderr
        end
      end
    end

    describe 'with a multi-line String' do
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighter!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end

      it 'should write the message to STDERR with a newline' do
        expect { standard_io.write_error(message) }
          .to output("#{message}\n")
          .to_stderr
      end

      describe 'with newline: false' do
        it 'should write the message to STDERR' do
          expect { standard_io.write_error(message, newline: false) }
            .to output(message)
            .to_stderr
        end
      end

      describe 'with newline: true' do
        it 'should write the message to STDERR with a newline' do
          expect { standard_io.write_error(message, newline: true) }
            .to output("#{message}\n")
            .to_stderr
        end
      end
    end

    context 'when initialized with error_stream: value' do
      let(:error_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(error_stream:) }

      describe 'with an empty String' do
        it 'should not write to STDERR' do
          expect { standard_io.write_error('') }
            .not_to output
            .to_stderr
        end

        it 'should write to the error stream' do
          standard_io.write_error('')

          expect(error_stream.string).to be == "\n"
        end
      end

      describe 'with a non-empty String' do
        let(:message) { 'Greetings, programs!' }

        it 'should not write to STDERR' do
          expect { standard_io.write_error(message) }
            .not_to output
            .to_stderr
        end

        it 'should write to the error stream' do
          standard_io.write_error(message)

          expect(error_stream.string).to be == "#{message}\n"
        end
      end
    end
  end

  describe '#write_output' do
    it 'should define the method' do
      expect(standard_io)
        .to respond_to(:write_output)
        .with(0..1).arguments
        .and_keywords(:newline)
    end

    describe 'with no parameters' do
      it { expect { standard_io.write_output }.to output("\n").to_stdout }
    end

    describe 'with no message and newline: false' do
      it 'should not write to STDOUT' do
        expect { standard_io.write_output(newline: false) }
          .not_to output
          .to_stdout
      end
    end

    describe 'with no message and newline: true' do
      it 'should write a newline to STDOUT' do
        expect { standard_io.write_output(newline: true) }
          .to output("\n")
          .to_stdout
      end
    end

    describe 'with an empty String' do
      let(:message) { '' }

      it 'should write a newline to STDOUT' do
        expect { standard_io.write_output(message) }
          .to output("\n")
          .to_stdout
      end

      describe 'with newline: false' do
        it 'should not write to STDOUT' do
          expect { standard_io.write_output(message, newline: false) }
            .not_to output
            .to_stdout
        end
      end

      describe 'with newline: true' do
        it 'should write a newline to STDOUT' do
          expect { standard_io.write_output(message, newline: true) }
            .to output("\n")
            .to_stdout
        end
      end
    end

    describe 'with a non-empty String' do
      let(:message) { 'Greetings, programs!' }

      it 'should write the message to STDOUT with a newline' do
        expect { standard_io.write_output(message) }
          .to output("#{message}\n")
          .to_stdout
      end

      describe 'with newline: false' do
        it 'should write the message to STDOUT' do
          expect { standard_io.write_output(message, newline: false) }
            .to output(message)
            .to_stdout
        end
      end

      describe 'with newline: true' do
        it 'should write the message to STDOUT with a newline' do
          expect { standard_io.write_output(message, newline: true) }
            .to output("#{message}\n")
            .to_stdout
        end
      end
    end

    describe 'with a String ending with a newline' do
      let(:message) { "Greetings, programs!\n" }

      it 'should write the message to STDOUT' do
        expect { standard_io.write_output(message) }
          .to output(message)
          .to_stdout
      end

      describe 'with newline: false' do
        it 'should write the message to STDOUT' do
          expect { standard_io.write_output(message, newline: false) }
            .to output(message)
            .to_stdout
        end
      end

      describe 'with newline: true' do
        it 'should write the message to STDOUT' do
          expect { standard_io.write_output(message, newline: true) }
            .to output(message)
            .to_stdout
        end
      end
    end

    describe 'with a multi-line String' do
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighter!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end

      it 'should write the message to STDOUT with a newline' do
        expect { standard_io.write_output(message) }
          .to output("#{message}\n")
          .to_stdout
      end

      describe 'with newline: false' do
        it 'should write the message to STDOUT' do
          expect { standard_io.write_output(message, newline: false) }
            .to output(message)
            .to_stdout
        end
      end

      describe 'with newline: true' do
        it 'should write the message to STDOUT with a newline' do
          expect { standard_io.write_output(message, newline: true) }
            .to output("#{message}\n")
            .to_stdout
        end
      end
    end

    context 'when initialized with output_stream: value' do
      let(:output_stream)       { StringIO.new }
      let(:constructor_options) { super().merge(output_stream:) }

      describe 'with an empty String' do
        it 'should not write to STDOUT' do
          expect { standard_io.write_output('') }
            .not_to output
            .to_stdout
        end

        it 'should write to the output stream' do
          standard_io.write_output('')

          expect(output_stream.string).to be == "\n"
        end
      end

      describe 'with a non-empty String' do
        let(:message) { 'Greetings, programs!' }

        it 'should not write to STDOUT' do
          expect { standard_io.write_output(message) }
            .not_to output
            .to_stdout
        end

        it 'should write to the output stream' do
          standard_io.write_output(message)

          expect(output_stream.string).to be == "#{message}\n"
        end
      end
    end
  end
end
