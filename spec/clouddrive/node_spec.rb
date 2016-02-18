require 'spec_helper'

describe CloudDrive::Node do
  describe '.upload_dir' do
    let(:filename) { 'filename' }
    let(:src_path) { '/root/srcpath' }
    let(:src_file_path) { "#{src_path}/#{filename}" }
    let(:dest_path) { 'dest/path' }
    context 'without passing options' do
      before { CloudDrive::Node.class_variable_set :@@account, double(CloudDrive::Account, :token_store => { :last_authorized => Time.new.to_i + 1000 }) }
      after { CloudDrive::Node.class_variable_set :@@account, nil }
      it do
        expect(Find).to receive(:find).and_yield src_file_path
        expect(CloudDrive::Node).to receive(:upload_file).with(src_file_path, "#{dest_path}/srcpath", {}).and_return(
          :success => true
        )
        expect(CloudDrive::Node.upload_dir(src_path, dest_path)).to eq [:success => true]
      end
    end

    context 'with passing options' do
      before { CloudDrive::Node.class_variable_set :@@account, double(CloudDrive::Account, :token_store => { :last_authorized => Time.new.to_i + 1000 }) }
      after { CloudDrive::Node.class_variable_set :@@account, nil }
      it do
        expect(Find).to receive(:find).and_yield src_file_path
        expect(CloudDrive::Node).to receive(:upload_file).with(src_file_path, "#{dest_path}/srcpath", :overwrite => true, :allow_duplicates => true).and_return(
          :success => true
        )
        expect(CloudDrive::Node.upload_dir(src_path, dest_path, nil, :overwrite => true, :allow_duplicates => true)).to eq [:success => true]
      end
    end
  end

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
        expect(RestClient).to receive(:post).and_yield double(RestClient::Response, :body => '{}', :code => 201)
        expect(CloudDrive::Node).to receive(:new).with({}).and_return(double(CloudDrive::Node, :save => nil))

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq(
          :success => true,
          :data => {},
          :status_code => 201
        )
      end
    end

    context 'when MD5 and Path do not match and the upload is not successful' do
      let(:exists_return) { {} }
      before { CloudDrive::Node.class_variable_set :@@account, double(CloudDrive::Account, :content_url => 'content url', :token_store => {}) }
      after { CloudDrive::Node.class_variable_set :@@account, nil }
      it do
        expect(File).to receive(:new).with(src_path, 'rb').and_return double(File)
        expect(RestClient).to receive(:post).and_yield double(RestClient::Response, :body => '{}', :code => 500)
        expect(CloudDrive::Node).not_to receive :new

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq(
          :success => false,
          :data => {},
          :status_code => 500
        )
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

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq(
          :success => false,
          :data => success_data,
          :status_code => nil
        )
      end
    end

    context 'when MD5 and Path match' do
      let(:exists_return) do
        {
          :success => true,
          :data => success_data
        }
      end
      let(:success_data) do
        {
          'md5_match' => true,
          'path_match' => true
        }
      end
      it do
        expect(File).not_to receive :new
        expect(RestClient).not_to receive :post

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq(
          :success => true,
          :data => success_data,
          :status_code => nil
        )
      end
    end

    context 'when MD5 matches and Path does not match and options[:allow_duplicates] == true' do
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
      before { CloudDrive::Node.class_variable_set :@@account, double(CloudDrive::Account, :content_url => 'content url', :token_store => {}) }
      after { CloudDrive::Node.class_variable_set :@@account, nil }
      it do
        expect(File).to receive(:new).with(src_path, 'rb').and_return double(File)
        expect(RestClient).to receive(:post).and_yield double(RestClient::Response, :body => '{}', :code => 201)
        expect(CloudDrive::Node).to receive(:new).with({}).and_return(double(CloudDrive::Node, :save => nil))

        expect(CloudDrive::Node.upload_file(src_path, dest_path, :allow_duplicates => true)).to eq(
          :success => true,
          :data => {},
          :status_code => 201
        )
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

        expect(CloudDrive::Node.upload_file(src_path, dest_path)).to eq(
          :success => false,
          :data => success_data,
          :status_code => nil
        )
      end
    end

    context 'when MD5 does not match and Path matches and options[:overwrite] == true' do
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

        expect(CloudDrive::Node.upload_file(src_path, dest_path, :overwrite => true)).to eq({})
      end
    end
  end
end
