module CloudDrive

  class InitCommand < Command

    def execute
      read_config

      case @config['database.driver']
        when 'sqlite'
          cache = Sqlite.new(@config['email'], @cache_path)
        else
          return
      end

      account = Account.new(@config['email'], @config['client-id'], @config['client-secret'], cache)
      response = account.authorize
      if !response[:sucess]
        puts response[:data]["message"]
        if response[:data].has_key?("auth_url")
          puts response[:data]["auth_url"]
          redirect_url = STDIN.gets
          response = account.authorize(redirect_url)
          if !response[:success]
            puts response[:data]["message"]
          else
            info("Successfully authenticated with Amazon Cloud Drive")
          end
        end
      end
    end

  end

end
