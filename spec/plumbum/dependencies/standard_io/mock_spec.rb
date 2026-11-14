# frozen_string_literal: true

require 'plumbum/dependencies/standard_io/mock'

RSpec.describe Plumbum::Dependencies::StandardIo::Mock do
  subject(:mock_io) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.append_for_read' do
    let(:io) { StringIO.new }
    let(:message) do
      'Greetings, starfighter!'
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:append_for_read)
        .with(1).argument
        .and_unlimited_arguments
        .and_keywords(:io)
    end

    it { expect(described_class.append_for_read(message, io:)).to be io }

    it 'should append the string to the stream', :aggregate_failures do
      expect { described_class.append_for_read(message, io:) }.to(
        change { io.string.length }.by(message.length + 1)
      )

      expect(io.string).to end_with("#{message}\n")
    end

    describe 'with a message ending in a newline' do
      let(:message) do
        "Greetings, starfighter!\n"
      end

      it 'should append the string to the stream', :aggregate_failures do
        expect { described_class.append_for_read(message, io:) }.to(
          change { io.string.length }.by(message.length)
        )

        expect(io.string).to end_with(message)
      end
    end

    describe 'with a multi-line message' do
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighters!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end

      it 'should append the string to the stream', :aggregate_failures do
        expect { described_class.append_for_read(message, io:) }.to(
          change { io.string.length }.by(message.length + 1)
        )

        expect(io.string).to end_with("#{message}\n")
      end
    end

    describe 'with multiple messages' do
      let(:messages) do
        [
          'Greetings, starfighters!',
          "\n",
          'You have been recruited by the Star League to defend the frontier ' \
          'against Xur and the Ko-Dan Armada!'
        ]
      end
      let(:expected) do
        messages
          .map { |str| str.end_with?("\n") ? str : "#{str}\n" }
          .join
      end

      it 'should append the string to the stream', :aggregate_failures do
        expect { described_class.append_for_read(*messages, io:) }.to(
          change { io.string.length }.by(expected.length)
        )

        expect(io.string).to end_with(expected)
      end
    end
  end

  describe '#color' do
    let(:text)       { 'Greetings, starfighter!' }
    let(:color_code) { 0 }
    let(:expected)   { "\e[#{color_code}m#{text}\e[0m" }

    it { expect(mock_io).to respond_to(:color).with(2).arguments }

    describe 'with color name: an invalid value' do
      let(:color) { 'octarine' }
      let(:error_message) do
        {}.fetch(color)
      rescue KeyError => exception
        exception.message
      end

      it 'should raise an exception' do
        expect { mock_io.color(text, color) }
          .to raise_error KeyError, error_message
      end
    end

    describe 'with color name: black' do
      let(:color_code) { 0 }

      it { expect(mock_io.color(text, 'black')).to be == expected }
    end

    describe 'with color name: blue' do
      let(:color_code) { 34 }

      it { expect(mock_io.color(text, 'blue')).to be == expected }
    end

    describe 'with color name: green' do
      let(:color_code) { 32 }

      it { expect(mock_io.color(text, 'green')).to be == expected }
    end

    describe 'with color name: purple' do
      let(:color_code) { 35 }

      it { expect(mock_io.color(text, 'purple')).to be == expected }
    end

    describe 'with color name: red' do
      let(:color_code) { 31 }

      it { expect(mock_io.color(text, 'red')).to be == expected }
    end

    describe 'with color name: yellow' do
      let(:color_code) { 33 }

      it { expect(mock_io.color(text, 'yellow')).to be == expected }
    end
  end

  describe '#combined_stream' do
    include_examples 'should define reader',
      :combined_stream,
      -> { be_a(StringIO).and(satisfy { |io| io.string.empty? }) }

    context 'when input data is requested' do
      let(:expected) do
        "Enter Your Name:\n> "
      end

      before(:example) do
        mock_io.write_output('Enter Your Name:')
        mock_io.write_output('> ', newline: false)
        mock_io.read_input
      end

      it { expect(mock_io.combined_stream.string).to be == expected }

      context 'when the input stream has unread data' do
        let(:input_stream)        { StringIO.new("Alex Rogan\n") }
        let(:constructor_options) { super().merge(input_stream:) }
        let(:expected) do
          "Enter Your Name:\n> Alex Rogan\n"
        end

        it { expect(mock_io.combined_stream.string).to be == expected }
      end
    end

    context 'when output data is written' do
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighters!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end
      let(:expected) { "#{message}\n" }

      before(:example) { mock_io.write_output(message) }

      it { expect(mock_io.combined_stream.string).to be == expected }
    end

    context 'when error data is written' do
      let(:warning) do
        '[WARNING] Death Blossom is a weapon of last resort.'
      end
      let(:expected) { "#{warning}\n" }

      before(:example) { mock_io.write_error(warning) }

      it { expect(mock_io.combined_stream.string).to be == expected }
    end

    context 'when there are multiple IO events' do
      let(:input_stream)        { StringIO.new("Alex Rogan\n") }
      let(:constructor_options) { super().merge(input_stream:) }
      let(:message) do
        <<~MESSAGE.strip
          Greetings, starfighters!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!
        MESSAGE
      end
      let(:warning) do
        '[WARNING] Death Blossom is a weapon of last resort.'
      end
      let(:expected) do
        <<~EXPECTED
          Enter Your Name:
          > Alex Rogan

          Greetings, starfighters!

          You have been recruited by the Star League to defend the frontier
          against Xur and the Ko-Dan Armada!

          [WARNING] Death Blossom is a weapon of last resort.
        EXPECTED
      end

      before(:example) do
        mock_io.write_output('Enter Your Name:')
        mock_io.write_output('> ', newline: false)
        mock_io.read_input

        mock_io.write_output
        mock_io.write_output(message)
        mock_io.write_output

        mock_io.write_error(warning)
      end

      it 'should combine the input and output streams' do
        # Danger: Crossing streams may result in total protonic reversal.
        expect(mock_io.combined_stream.string).to be == expected
      end
    end
  end

  describe '#error_stream' do
    include_examples 'should define reader',
      :error_stream,
      -> { be_a(StringIO).and(satisfy { |io| io.string.empty? }) }

    context 'when initialized with error_stream: value' do
      let(:error_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(error_stream:) }

      it { expect(mock_io.error_stream).to be error_stream }
    end
  end

  describe '#input_stream' do
    include_examples 'should define reader',
      :input_stream,
      -> { be_a(StringIO).and(satisfy { |io| io.string.empty? }) }

    context 'when initialized with input_stream: value' do
      let(:input_stream)        { StringIO.new }
      let(:constructor_options) { super().merge(input_stream:) }

      it { expect(mock_io.input_stream).to be input_stream }
    end
  end

  describe '#output_stream' do
    include_examples 'should define reader',
      :output_stream,
      -> { be_a(StringIO).and(satisfy { |io| io.string.empty? }) }

    context 'when initialized with output_stream: value' do
      let(:output_stream)       { StringIO.new }
      let(:constructor_options) { super().merge(output_stream:) }

      it { expect(mock_io.output_stream).to be output_stream }
    end
  end

  describe '#read_input' do
    it { expect(mock_io).to respond_to(:read_input).with(0).arguments }

    it { expect(mock_io.read_input).to be nil }

    it 'should not update the combined stream' do
      expect { mock_io.read_input }
        .not_to change(mock_io.combined_stream, :string)
    end

    context 'when the input stream has unread data' do
      let(:raw_input) { "Greetings, programs!\n" }

      before(:example) do
        described_class.append_for_read(raw_input, io: mock_io.input_stream)
      end

      it { expect(mock_io.read_input).to be == raw_input }

      it 'should append the input to the combined stream' do
        expect { mock_io.read_input }
          .to change(mock_io.combined_stream, :string)
          .to(satisfy { |str| str.end_with?(raw_input) })
      end
    end
  end

  describe '#write_error' do
    it 'should define the method' do
      expect(mock_io)
        .to respond_to(:write_error)
        .with(0..1).arguments
        .and_keywords(:newline)
    end

    describe 'with no parameters' do
      it { expect { mock_io.write_error }.not_to output.to_stderr }

      it 'should write a newline to the error stream' do
        mock_io.write_error

        expect(mock_io.error_stream.string).to be == "\n"
      end
    end

    describe 'with no message and newline: false' do
      it 'should not write to the error stream' do
        mock_io.write_error(newline: false)

        expect(mock_io.error_stream.string).to be == ''
      end
    end

    describe 'with no message and newline: true' do
      it 'should write a newline to the error stream' do
        mock_io.write_error(newline: true)

        expect(mock_io.error_stream.string).to be == "\n"
      end
    end

    describe 'with an empty String' do
      let(:message) { '' }

      it { expect { mock_io.write_error }.not_to output.to_stderr }

      it 'should write a newline to the error stream' do
        mock_io.write_error('')

        expect(mock_io.error_stream.string).to be == "\n"
      end

      describe 'with newline: false' do
        it 'should not write to the error stream' do
          mock_io.write_error('', newline: false)

          expect(mock_io.error_stream.string).to be == ''
        end
      end

      describe 'with newline: true' do
        it 'should write a newline to the error stream' do
          mock_io.write_error('', newline: true)

          expect(mock_io.error_stream.string).to be == "\n"
        end
      end
    end

    describe 'with a non-empty String' do
      let(:message) { 'Greetings, programs!' }

      it 'should write the message to the error stream with a newline' do
        mock_io.write_error(message)

        expect(mock_io.error_stream.string).to be == "#{message}\n"
      end

      it 'should append the output to the combined stream' do
        expect { mock_io.write_error(message) }
          .to change(mock_io.combined_stream, :string)
          .to(satisfy { |str| str.end_with?("#{message}\n") })
      end

      describe 'with newline: false' do
        it 'should write the message to the error stream' do
          mock_io.write_error(message, newline: false)

          expect(mock_io.error_stream.string).to be == message
        end

        it 'should append the output to the combined stream' do
          expect { mock_io.write_error(message, newline: false) }
            .to change(mock_io.combined_stream, :string)
            .to(satisfy { |str| str.end_with?(message) })
        end
      end

      describe 'with newline: true' do
        it 'should write the message to the error stream with a newline' do
          mock_io.write_error(message)

          expect(mock_io.error_stream.string).to be == "#{message}\n"
        end

        it 'should append the output to the combined stream' do
          expect { mock_io.write_error(message, newline: true) }
            .to change(mock_io.combined_stream, :string)
            .to(satisfy { |str| str.end_with?("#{message}\n") })
        end
      end
    end
  end

  describe '#write_output' do
    it 'should define the method' do
      expect(mock_io)
        .to respond_to(:write_output)
        .with(0..1).arguments
        .and_keywords(:newline)
    end

    describe 'with no parameters' do
      it { expect { mock_io.write_output }.not_to output.to_stdout }

      it 'should write a newline to the error stream' do
        mock_io.write_output

        expect(mock_io.output_stream.string).to be == "\n"
      end
    end

    describe 'with no message and newline: false' do
      it 'should not write to the error stream' do
        mock_io.write_output(newline: false)

        expect(mock_io.output_stream.string).to be == ''
      end
    end

    describe 'with no message and newline: true' do
      it 'should write a newline to the error stream' do
        mock_io.write_output(newline: true)

        expect(mock_io.output_stream.string).to be == "\n"
      end
    end

    describe 'with an empty String' do
      let(:message) { '' }

      it { expect { mock_io.write_output }.not_to output.to_stdout }

      it 'should write a newline to the error stream' do
        mock_io.write_output('')

        expect(mock_io.output_stream.string).to be == "\n"
      end

      describe 'with newline: false' do
        it 'should not write to the error stream' do
          mock_io.write_output('', newline: false)

          expect(mock_io.output_stream.string).to be == ''
        end
      end

      describe 'with newline: true' do
        it 'should write a newline to the error stream' do
          mock_io.write_output('', newline: true)

          expect(mock_io.output_stream.string).to be == "\n"
        end
      end
    end

    describe 'with a non-empty String' do
      let(:message) { 'Greetings, programs!' }

      it 'should write the message to the error stream with a newline' do
        mock_io.write_output(message)

        expect(mock_io.output_stream.string).to be == "#{message}\n"
      end

      it 'should append the output to the combined stream' do
        expect { mock_io.write_output(message) }
          .to change(mock_io.combined_stream, :string)
          .to(satisfy { |str| str.end_with?("#{message}\n") })
      end

      describe 'with newline: false' do
        it 'should write the message to the error stream' do
          mock_io.write_output(message, newline: false)

          expect(mock_io.output_stream.string).to be == message
        end

        it 'should append the output to the combined stream' do
          expect { mock_io.write_output(message, newline: false) }
            .to change(mock_io.combined_stream, :string)
            .to(satisfy { |str| str.end_with?(message) })
        end
      end

      describe 'with newline: true' do
        it 'should write the message to the error stream with a newline' do
          mock_io.write_output(message)

          expect(mock_io.output_stream.string).to be == "#{message}\n"
        end

        it 'should append the output to the combined stream' do
          expect { mock_io.write_output(message, newline: true) }
            .to change(mock_io.combined_stream, :string)
            .to(satisfy { |str| str.end_with?("#{message}\n") })
        end
      end
    end
  end
end
