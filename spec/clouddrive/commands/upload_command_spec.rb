require 'spec_helper'
require 'json'

describe CloudDrive::UploadCommand do
  describe '#execute' do
    let(:command) { CloudDrive::UploadCommand.new '.' }
    let(:config_file_location) { %r{/\.cache/clouddrive-ruby/config\.json\z} }
    let(:config) { {} }
    let(:src_path) { '/src/path' }
    let(:remote_path) { 'remote/path' }
    let(:results_method) { command.method :display_file_results }
    before do
      allow(File).to receive(:exist?).with(config_file_location).and_return true
      allow(File).to receive(:read).with(config_file_location).and_return config.to_json
      allow(CloudDrive::Sqlite).to receive(:new).and_return double(CloudDrive::Sqlite)
      allow(CloudDrive::Account).to receive(:new).and_return double(CloudDrive::Account, :authorize => { :success => true })
      allow(CloudDrive::Node).to receive :init
      allow(File).to receive(:exist?).with(src_path).and_return true
    end
    context 'uploading a directory without passing the --overwrite option' do
      it do
        expect(File).to receive(:directory?).with(src_path).and_return true
        expect(CloudDrive::Node).to receive(:upload_dir).with src_path, remote_path, results_method, :overwrite => false, :allow_duplicates => false

        command.run [src_path, remote_path]
      end
    end

    context 'uploading a directory and passing the --overwrite option' do
      it do
        expect(File).to receive(:directory?).with(src_path).and_return true
        expect(CloudDrive::Node).to receive(:upload_dir).with src_path, remote_path, results_method, :overwrite => true, :allow_duplicates => false

        command.run ['--overwrite', src_path, remote_path]
      end
    end

    context 'uploading a directory when config[upload.duplicates] == true' do
      let(:config) { { 'upload.duplicates' => true } }
      it do
        expect(File).to receive(:directory?).with(src_path).and_return true
        expect(CloudDrive::Node).to receive(:upload_dir).with src_path, remote_path, results_method, :overwrite => false, :allow_duplicates => true

        command.run [src_path, remote_path]
      end
    end

    context 'uploading a file without passing the --overwrite option' do
      it do
        expect(File).to receive(:directory?).with(src_path).and_return false
        expect(CloudDrive::Node).
          to receive(:upload_file).
          with(src_path, remote_path, :overwrite => false, :allow_duplicates => false).
          and_return :success => true

        command.run [src_path, remote_path]
      end
    end

    context 'uploading a file and passing the --overwrite option' do
      it do
        expect(File).to receive(:directory?).with(src_path).and_return false
        expect(CloudDrive::Node).
          to receive(:upload_file).
          with(src_path, remote_path, :overwrite => true, :allow_duplicates => false).
          and_return :success => true

        command.run ['--overwrite', src_path, remote_path]
      end
    end

    context 'uploading a file when config[upload.duplicates] == true' do
      let(:config) { { 'upload.duplicates' => true } }
      it do
        expect(File).to receive(:directory?).with(src_path).and_return false
        expect(CloudDrive::Node).
          to receive(:upload_file).
          with(src_path, remote_path, :overwrite => false, :allow_duplicates => true).
          and_return :success => true

        command.run [src_path, remote_path]
      end
    end
  end
end
