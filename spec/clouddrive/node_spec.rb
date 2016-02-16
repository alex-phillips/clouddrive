require 'spec_helper'

describe CloudDrive::Node do
  describe '.upload_file' do
    let(:filename) { 'filename' }
    let(:src_path) { "/src/path/to/#{filename}" }
    let(:dest_path) { 'dest/path' }
    before do
      expect(CloudDrive::Node).to receive(:load_by_path).with(dest_path).and_return double(CloudDrive::Node, :get_id => 'an id')
      expect(CloudDrive::Node).to receive(:exists?).with("#{dest_path}/#{filename}", src_path).and_return exists_return
    end
    context 'when MD5 and Path do not match' do
      let(:exists_return) { {} }
      before { CloudDrive::Node.class_variable_set :@@account, double(CloudDrive::Account, :content_url => 'content url', :token_store => {}) }
      after { CloudDrive::Node.class_variable_set :@@account, nil }
      it do
        expect(File).to receive(:new).with(src_path, 'rb').and_return double(File)
        expect(RestClient).to receive :post

        CloudDrive::Node.upload_file src_path, dest_path
      end
    end

    context 'when MD5 matches and Path does not match' do
      let(:exists_return) do
        {
          :success => true,
          :data => success_data
        }
      end
      let(:success_data) do
        {
          'md5_match' => true,
          'path_match' => false
        }
      end
      it do
        expect(File).not_to receive :new
        expect(RestClient).not_to receive :post

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq({
          :success => false,
          :data => success_data,
          :status_code => nil
        })
      end
    end

    context 'when MD5 does not match and Path matches' do
      let(:exists_return) do
        {
          :success => true,
          :data => success_data
        }
      end
      let(:success_data) do
        {
          'md5_match' => false,
          'path_match' => true
        }
      end
      it do
        expect(File).not_to receive :new
        expect(RestClient).not_to receive :post

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq({
          :success => false,
          :data => success_data,
          :status_code => nil
        })
      end
    end

    context 'when MD5 does not match and Path matches and overwrite == true' do
      let(:node_double) { double(CloudDrive::Node) }
      let(:exists_return) do
        {
          :success => true,
          :data => success_data
        }
      end
      let(:success_data) do
        {
          'md5_match' => false,
          'path_match' => true,
          'node' => node_double
        }
      end
      it do
        expect(node_double).to receive(:overwrite).with(src_path).and_return({})
        expect(File).not_to receive :new
        expect(RestClient).not_to receive :post

        expect(CloudDrive::Node.upload_file(src_path, dest_path, true)).to eq({})
      end
    end
  end
end
