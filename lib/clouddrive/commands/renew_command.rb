module CloudDrive

  class RenewCommand < CloudDrive::BaseCommand

    def execute
      config = read_config
      account = CloudDrive::Account.new(config[:email], config[:client_id], config[:client_secret])
      account.renew_authorization
    end

  end

end
