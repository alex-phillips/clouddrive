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
      node = CloudDrive::Node.new(account)

      if File.directory?(src)
        results = node.upload_dir(src, dest)
        results.each do |result|
          if result[:success] == false
            puts result[:data]["message"]
          end
        end
      else
        result = node.upload_file(src, dest)
        puts result.to_json
      end
    end

  end

end