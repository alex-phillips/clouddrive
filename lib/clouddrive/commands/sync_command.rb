module CloudDrive

  class SyncCommand < Command

    def execute
      @offline = false

      init
      puts "Syncing..."
      @account.sync
      puts "Done."
    end

  end

end
