require 'json'
require 'cgi'
require 'rest-client'
require 'sqlite3'

module CloudDrive

  class Account

    attr_reader :access_token, :metadata_url, :content_url, :email, :token_store, :db

    def initialize(email, client_id, client_secret)
      @email = email
      @cache_file = File.expand_path("~/.clouddrive/#{email}.cache")
      @client_id = client_id
      @client_secret = client_secret

      @db = SQLite3::Database.new(File.expand_path("~/.clouddrive/#{@email}.db"))
      if @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='nodes';").empty?
        @db.execute <<-SQL
         CREATE TABLE nodes(
            id VARCHAR PRIMARY KEY NOT NULL,
            name VARCHAR NOT NULL,
            kind VARCHAR NOT NULL,
            md5 VARCHAR,
            created DATETIME NOT NULL,
            modified DATETIME NOT NULL,
            raw_data TEXT NOT NULL
         );
        SQL
      end
    end

    def authorize(auth_url = nil)
      retval = {
        :success => true,
        :data => {}
      }

      @token_store = {
          "checkpoint" => nil,
          "nodes" => {}
      }

      if File.exists?(@cache_file)
        @token_store = JSON.parse(File.read(@cache_file))
      end

      if !@token_store.has_key?("access_token")
        if auth_url.nil?
          retval[:success] = false
          retval[:data]["message"] = "Initial authorization required."
          retval[:data]["auth_url"] = "https://www.amazon.com/ap/oa?client_id=#{@client_id}&scope=clouddrive%3Aread%20clouddrive%3Awrite&response_type=code&redirect_uri=http://localhost"

          return retval
        else
          data = request_authorization(auth_url)
        end

        if data[:success] === true
          @token_store = data[:data]
        else
          return data
        end

        save_token_store
      elsif (Time.new.to_i - @token_store["last_authorized"]) > 60
        data = renew_authorization
        if data[:success] === false
          return data
        end
      end

      @access_token = @token_store["access_token"]

      if !@token_store.has_key?("metadataUrl") || !@token_store.has_key?("contentUrl")
        result = get_endpoint
        if result[:success] === true
          @metadata_url = result[:data]["metadataUrl"]
          @content_url = result[:data]["contentUrl"]
          @token_store["contentUrl"] = @content_url
          @token_store["metadataUrl"] = @metadata_url

          save_token_store
        end
      end

      @metadata_url = @token_store["metadataUrl"]
      @content_url = @token_store["contentUrl"]

      retval
    end

    def clear_cache
      @token_store["nodes"] = {}
      @token_store["checkpoint"] = nil
      save_token_store
    end

    def get_endpoint
      retval = {
          :success => false,
          :data => {}
      }
      RestClient.get("https://cdws.us-east-1.amazonaws.com/drive/v1/account/endpoint", {:Authorization => "Bearer #{@access_token}"}) do |response, request, result|
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

      RestClient.get("#{@metadata_url}account/quota", {:Authorization => "Bearer #{@access_token}"}) do |response, request, result|
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

      RestClient.get("#{@metadata_url}account/usage", {:Authorization => "Bearer #{@access_token}"}) do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
        end
      end

      retval
    end

    def nodes
      @token_store["nodes"]
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

    def renew_authorization
      retval = {
          :success => false,
          :data => {}
      }

      body = {
          'grant_type' => "refresh_token",
          'refresh_token' => @token_store["refresh_token"],
          'client_id' => @client_id,
          'client_secret' => @client_secret,
          'redirect_uri' => "http://localhost"
      }
      RestClient.post("https://api.amazon.com/auth/o2/token", body, :content_type => 'application/x-www-form-urlencoded') do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true

          @token_store["last_authorized"] = Time.new.to_i
          @token_store["refresh_token"] = retval[:data]["refresh_token"]
          @token_store["access_token"] = retval[:data]["access_token"]

          @access_token = @token_store["access_token"]
          @refresh_token = @token_store["refresh_token"]

          save_token_store
        end
      end

      retval
    end

    def save_token_store
      File.open(@cache_file, 'w') do |file|
        file.write(@token_store.to_json)
      end
    end

    def sync
      if !@token_store.has_key?("checkpoint")
        @token_store["checkpoint"] = nil
      end

      body = {
          :includePurged => "true"
      }

      loop do
        if @token_store["checkpoint"] != nil
          body[:checkpoint] = @token_store["checkpoint"]
        end

        loop = true
        RestClient.post(@metadata_url + "changes", body.to_json, :Authorization => "Bearer #{@access_token}") do |response, request, result|
          if response.code === 200
            data = response.body.split("\n")
            data.each do |xary|
              xary = JSON.parse(xary)
              if xary.has_key?("reset") && xary["reset"] == true
                @db.execute("DELETE FROM nodes WHERE 1=1")
              end

              if xary.has_key?("end") && xary["end"] == true
                loop = false
              elsif xary.has_key?("nodes")
                @token_store["checkpoint"] = xary["checkpoint"]
                xary["nodes"].each do |node|
                  if node["status"] == "PURGED"
                    delete_node_by_id(node["id"])
                  else
                    save_node(node)
                  end
                end
              end
            end
          end
        end

        break if loop === false
      end

      save_token_store
    end

    def delete_node_by_id(id)
      begin
        @db.execute("DELETE FROM nodes WHERE id = ?", id)
      rescue SQLite3::Exception => e
        puts "Exception deleting node with ID #{id}: #{e}"
      end
    end

    def save_node(node)
      md5 = nil
      if node["contentProperties"] != nil && node["contentProperties"]["md5"] != nil
        md5 = node["contentProperties"]["md5"]
      end

      if node["name"] == nil && node["isRoot"] != nil && node["isRoot"] == true
        node["name"] = "root"
      end

      begin
        result = db.execute("INSERT OR REPLACE INTO nodes (id, name, kind, md5, created, modified, raw_data)
          VALUES (?, ?, ?, ?, ?, ?, ?);", [node["id"], node["name"], node["kind"], md5, node["createdDate"], node["modifiedDate"], node.to_json])
      rescue SQLite3::Exception => e
        if node["name"] == nil
          puts "Exception saving node: #{e}"
          puts node.to_json
        end
      end
    end

  end

end
