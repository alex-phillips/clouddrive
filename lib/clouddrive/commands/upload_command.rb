require 'colorize'

module CloudDrive

  class UploadCommand < Command

    parameter "local_path", "Local path to file/folder to upload"
    parameter "[remote_path]", "Remote path to upload the file(s) to"

    def execute
      @offline = false

      init

      source = File.expand_path(local_path)
      if !File.exists?(source)
        error("No file or folder exists at '#{source}'")
        exit
      end

      if File.directory?(source)
        Node.upload_dir(source, remote_path)
      else
        result = Node.upload_file(source, remote_path)
        if result[:success]
          info("Successfully uploaded '#{source}': #{result[:data].to_json}")
        else
          error("Failed to upload '#{source}': #{result[:data].to_json}")
        end
      end
    end

  end

end
