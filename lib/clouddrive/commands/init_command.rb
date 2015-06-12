require 'clouddrive/commands/base_command'

module CloudDrive

  class InitCommand < CloudDrive::BaseCommand

    def execute
      cmd_opts = options[:global][:commands][:init][:options]
      email = cmd_opts[:email]
      client_id = cmd_opts[:client_id]
      client_secret = cmd_opts[:client_secret]
      auth_url = cmd_opts[:auth_url]

      config = read_config

      if email != nil
        config[:email] = email
      end

      if client_id != nil
        config[:client_id] = client_id
      end

      if client_secret != nil
        config[:client_secret] = client_secret
      end

      if config[:email] == nil
        raise "Email required for authorization"
      end

      if config[:client_id] == nil || config[:client_secret] == nil
        raise "Amazon CloudDrive API credentials required"
      end

      save_config(config)

      account = CloudDrive::Account.new(config[:email], config[:client_id], config[:client_secret])
      result = account.authorize(auth_url)
      if result[:success] === false
        if result[:data]["message"] == "Initial authorization required."
          puts "Initiali authorization required. Navigate to the following URL and paste in the redirect URL here."
          puts result[:data]["auth_url"]
        end
      end
    end

  end

end
