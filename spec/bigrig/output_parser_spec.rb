module Bigrig
  describe OutputParser do
    describe '#parse' do
      subject do
        parser = described_class.new
        [input].flatten.map { |i| parser.parse i }.last
      end

      let(:mock_io) { double IO }
      let(:output) { subject }

      context 'with input that has a stream' do
        let(:input) { '{"stream": "value"}' }

        it 'returns the value of stream' do
          expect(output).to eq 'value'
        end
      end

      context 'with input that has no id and a status' do
        let(:input) { '{"status": "status_value"}' }

        it 'returns the value of status with a linefeed' do
          expect(output).to eq "status_value\n"
        end
      end

      context 'with input that has an id, status, and progress' do
        let(:input) { '{"id": "id", "status": "status", "progress" : "progress" }' }

        it 'formats the output with a trailing carrage return' do
          expect(output).to eq "id: status progress\r"
        end
      end

      context 'when the id changes' do
        let(:input) do
          ['{"id": "id", "status": "status", "progress" : "progress" }',
           '{"id": "new_id", "status": "status", "progress" : "progress" }']
        end

        it 'prints a linefeed' do
          expect(output).to eq "\nnew_id: status progress\r"
        end
      end

      context 'when the id noralizes after changing' do
        let(:input) do
          ['{"id": "id", "status": "status", "progress" : "progress" }',
           '{"id": "new_id", "status": "status", "progress" : "progress" }',
           '{"id": "new_id", "status": "status", "progress" : "progress" }']
        end

        it 'does not print a linefeed' do
          expect(output).to eq "new_id: status progress\r"
        end
      end

      context 'when a shorter message is returned with the same id' do
        let(:input) do
          ['{"id": "id", "status": "status", "progress" : "i am a much longer message" }',
           '{"id": "id", "status": "status", "progress" : "progress" }']
        end

        it 'pads the output' do
          expect(output).to eq "id: status progress                  \r"
        end
      end
    end
  end
end
