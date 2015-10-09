module CloudDrive

  class ClearCacheCommand < Command

    parameter "[path]", "Config option to read, write, or reset"

    def execute
      @offline = true

      init
      @account.clear_cache
    end

  end

end
