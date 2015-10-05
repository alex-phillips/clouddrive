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
        Node.upload_dir(source, remote_path, false, method(:display_file_results))
      else
        result = Node.upload_file(source, remote_path)
        display_file_results(source, remote_path, retval)
      end
    end

    def display_file_results(local_path, remote_path, retval)
      if retval[:success]
        info("Successfully uploaded '#{local_path}' to '#{remote_path}'")
      else
        error("Failed to upload '#{local_path}': #{retval[:data].to_json}")
      end
    end

  end

end
