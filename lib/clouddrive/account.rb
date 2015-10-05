require 'json'
require 'cgi'
require 'rest-client'
require 'sqlite3'

module CloudDrive

  class Account

    attr_reader :cache, :access_token, :metadata_url, :content_url, :email, :token_store, :checkpoint

    def initialize(email, client_id, client_secret, cache)
      @email = email
      @cache_file = File.expand_path("~/.cache/clouddrive-ruby/#{email}.cache")
      @client_id = client_id
      @client_secret = client_secret
      @cache = cache

      @redirect_uri = 'http://localhost'

      @scope = [
          'clouddrive:read_all',
          'clouddrive:write',
      ]

      config = @cache.load_account_config(@email)

      @token_store = config ? config : {}
    end

    def authorize(auth_url = nil)
      retval = {
          :success => true,
          :data => {}
      }

      scope = URI.escape(@scope.join(' '))

      response = {}
      if !@token_store.has_key?(:access_token)
        if auth_url.nil?
          retval = {
            :success => false,
            :data => {
              "message" => "Initial authorization required",
              "auth_url" => "https://www.amazon.com/ap/oa?client_id=#{@client_id}&scope=#{scope}&response_type=code&redirect_uri=#{@redirect_uri}"
            }
          }

          return retval
        end

        response = request_authorization(auth_url)

        return response if response[:success] === false
      elsif @token_store.has_key?(:last_authorized) && (Time.new.to_i - @token_store[:last_authorized]) > 60
        response = renew_authorization
        if response[:success] === false
          return response
        end
      end

      if response.has_key?(:data)
        response[:data].each do |key, value|
          @token_store[key.to_sym] = value
        end
      end

      if !@token_store.has_key?(:metadata_url) || !@token_store.has_key?(:content_url) || !@token_store[:metadata_url] || !@token_store[:content_url]
        result = get_endpoint
        if result[:success] === true
          @metadata_url = result[:data]["metadataUrl"]
          @content_url = result[:data]["contentUrl"]
          @token_store[:content_url] = result[:data]["contentUrl"]
          @token_store[:metadata_url] = result[:data]["metadataUrl"]
        end
      end

      @checkpoint = @token_store[:checkpoint]
      @metadata_url = @token_store[:metadata_url]
      @content_url = @token_store[:content_url]

      save

      retval
    end

    def clear_cache
      @checkpoint = nil
      save
      @cache.delete_all_nodes
    end

    def get_endpoint
      retval = {
          :success => false,
          :data => {}
      }
      RestClient.get("https://cdws.us-east-1.amazonaws.com/drive/v1/account/endpoint", {:Authorization => "Bearer #{@token_store[:access_token]}"}) do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
        end
      end

      retval
    end

    def get_quota
      retval = {
          :success => false,
          :data => {}
      }

      RestClient.get("#{@metadata_url}account/quota", {:Authorization => "Bearer #{@token_store[:access_token]}"}) do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
        end
      end

      retval
    end

    def get_usage
      retval = {
          :success => false,
          :data => {}
      }

      RestClient.get("#{@metadata_url}account/usage", {:Authorization => "Bearer #{@token_store[:access_token]}"}) do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
        end
      end

      retval
    end

    def renew_authorization
      retval = {
          :success => false,
          :data => {}
      }

      body = {
          'grant_type' => "refresh_token",
          'refresh_token' => @token_store[:refresh_token],
          'client_id' => @client_id,
          'client_secret' => @client_secret,
          'redirect_uri' => "http://localhost"
      }
      RestClient.post("https://api.amazon.com/auth/o2/token", body, :content_type => 'application/x-www-form-urlencoded') do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true

          retval[:data]["last_authorized"] = Time.new.to_i
        end
      end

      retval
    end

    def request_authorization(auth_url)
      retval = {
          :success => false,
          :data => {}
      }

      params = CGI.parse(URI.parse(auth_url).query)
      if !params.has_key?('code')
        retval[:data]["message"] = "No authorization code exists in the callback URL: #{params}"

        return retval
      end

      code = params["code"]

      # Get token
      #
      # @TODO: why do I need to do this with code? (i.e., code[0])
      body = {
          'grant_type' => "authorization_code",
          'code' => code[0],
          'client_id' => @client_id,
          'client_secret' => @client_secret,
          'redirect_uri' => "http://localhost"
      }

      RestClient.post("https://api.amazon.com/auth/o2/token", body, :content_type => 'application/x-www-form-urlencoded') do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
          retval[:data]["last_authorized"] = Time.new.to_i
        end
      end

      retval
    end

    def save
      @cache.save_account_config(self)
    end

    def set_scope(scopes)
      @scope = scopes
    end

    def sync
      body = {
          :maxNodes => 5000
      }

      if @checkpoint
        body[:includePurged] = "true"
      end

      loop do
        if @checkpoint
          body[:checkpoint] = @checkpoint
        end

        loop = true
        RestClient.post("#{@metadata_url}changes", body.to_json, :Authorization => "Bearer #{@token_store[:access_token]}") do |response, request, result|
          if response.code === 200
            data = response.body.split("\n")
            data.each do |xary|
              xary = JSON.parse(xary)
              if xary.has_key?("reset") && xary["reset"] == true
                @cache.delete_all_nodes
              end

              if xary.has_key?("nodes")
                @checkpoint = xary["checkpoint"]
                if xary["nodes"].empty?
                  loop = false
                else
                  xary["nodes"].each do |node|
                    node = Node.new(node)
                    if node.get_status == "PURGED"
                      node.delete
                    else
                      node.save
                    end
                  end
                end

                save
              end
            end
          end
        end

        break if loop === false
      end

      save
    end

  end

end
