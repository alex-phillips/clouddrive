module CloudDrive

  class UploadCommand < CloudDrive::BaseCommand

    def execute
      config = read_config

      if arguments[0] == nil
        raise "Source file/folder is required"
      end

      src = File.expand_path(arguments[0], Dir.pwd)

      dest = arguments[1]
      if dest == nil
        dest = ''
      end

      account = CloudDrive::Account.new(config[:email], config[:client_id], config[:client_secret])
      account.authorize
      node = CloudDrive::Node.new(account)

      if File.directory?(src)
        node.upload_dir(src, dest, true)
      else
        result = node.upload_file(src, dest)
        if result[:success] == true
          puts "Successfully uploaded file #{src}: #{result[:data].to_json}"
        else
          puts "Failed to uploaded file #{src}: #{result[:data].to_json}"
        end
      end
    end

  end

end
