module CloudDrive

  class QuotaCommand < Command

    def execute
      @offline = false

      init
      result = @account.get_quota
      if result[:success]
        puts result[:data].to_json
      else
        error("Failed to retrieve account quota: #{retval[:data].to_json}")
      end
    end

  end

end
