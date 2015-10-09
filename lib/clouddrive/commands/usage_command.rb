module CloudDrive

  class UsageCommand < Command

    def execute
      @offline = false

      init
      result = @account.get_usage
      if result[:success]
        puts result[:data].to_json
      else
        error("Failed to retrieve account usage: #{retval[:data].to_json}")
      end
    end

  end

end
