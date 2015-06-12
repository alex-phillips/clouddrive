require 'clouddrive/commands/base_command'

module CloudDrive

  class MetadataCommand < CloudDrive::BaseCommand

    def execute
      config = read_config
      account = CloudDrive::Account.new(config[:email], config[:client_id], config[:client_secret])
      account.authorize
      api = CloudDrive::Node.new(account)

      file = arguments[0]

      if (node = api.find_by_path(file)) != nil
        puts node.to_json
      else
        puts "File does not exist."
      end
    end

  end

end
