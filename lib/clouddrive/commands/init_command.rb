require 'clouddrive/commands/base_command'

module CloudDrive

  class InitCommand < CloudDrive::BaseCommand

    def execute
      cmd_opts = options[:global][:commands][:init][:options]
      email = cmd_opts[:email]
      client_id = cmd_opts[:client_id]
      client_secret = cmd_opts[:client_secret]

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

      save_config(config)
    end

  end

end