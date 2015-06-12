module CloudDrive

  class SyncCommand < CloudDrive::BaseCommand

    def execute
      config = read_config
      account = CloudDrive::Account.new(config[:email], config[:client_id], config[:client_secret])
      account.authorize
      account.sync
    end

  end

end
