module CloudDrive

  class ClearCacheCommand < CloudDrive::BaseCommand

    def execute
      config = read_config
      account = CloudDrive::Account.new(config[:email], config[:client_id], config[:client_secret])
      account.authorize
      account.clear_cache
    end

  end

end
