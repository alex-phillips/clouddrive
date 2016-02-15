require 'spec_helper'

describe CloudDrive::Command do
  describe '#read_config' do
    let(:config_file_location) { %r{/\.cache/clouddrive-ruby/config\.json\z} }
    let(:command) { CloudDrive::Command.new nil }
    subject(:read_config) { command.read_config }
    context 'when the config file exists' do
      it do
        expect(File).to receive(:exist?).with(config_file_location).and_return true
        expect(File).to receive(:read).with(config_file_location).and_return '{}'

        read_config

        expect(command.instance_variable_get(:@config)['database.driver']).to eq 'sqlite'
      end
    end
    context 'when the config file does not exist' do
      it do
        expect(File).to receive(:exist?).with(config_file_location).and_return false

        read_config

        expect(command.instance_variable_get(:@config)).to eq({})
      end
    end
  end
end
