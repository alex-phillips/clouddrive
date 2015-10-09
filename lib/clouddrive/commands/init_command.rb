module CloudDrive

  class InitCommand < Command

    def execute
      read_config

      cache = generate_cache

      account = Account.new(@config['email'], @config['client-id'], @config['client-secret'], cache)
      response = account.authorize
      unless response[:sucess]
        puts response[:data]["message"]

        if response[:data].has_key?("auth_url")
          puts response[:data]["auth_url"]
          redirect_url = STDIN.gets
          response = account.authorize(redirect_url)

          if response[:success]
            info("Successfully authenticated with Amazon Cloud Drive")
          else
            puts response[:data]["message"]
          end
        end
      end
    end

  end

end
