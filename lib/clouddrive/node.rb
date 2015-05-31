require 'rest-client'
require 'pathname'
require 'find'
require 'digest/md5'
require 'json'

module CloudDrive

  class Node

    def initialize(account)
      @account = account
    end

    def build_node_path(node)
      path = []
      loop do
        path.push node["name"]

        break if node.has_key?('isRoot') && node['isRoot'] == true

        node = @account.nodes[node["parents"][0]]

        break if node.has_key?('isRoot') && node['isRoot'] === true
      end

      path = path.reverse
      path.join('/')
    end

    def create_new_folder(name, parent_id = nil)
      if parent_id == nil
        parent_id = get_root['id']
      end

      body = {
          :name => name,
          :parents => [
              parent_id
          ],
          :kind => "FOLDER"
      }

      retval = {
          :success => false,
          :data => []
      }

      RestClient.post(
          "#{@account.metadata_url}nodes",
          body.to_json,
          :Authorization => "Bearer #{@account.access_token}"
      ) do |response, request, result|
        data = JSON.parse(response.body)
        retval[:data] = data
        if response.code === 201
          retval[:success] = true
          @account.update_node(data["id"], data)
        end
      end

      retval
    end

    def create_directory_path(path)
      path = get_path_array(path)
      previous_node = get_root

      match = nil
      path.each_with_index do |folder, index|
        xary = path.slice(0, index + 1)
        if (match = find_by_path(xary.join('/'))) === nil
          result = create_new_folder(folder, previous_node["id"])
          if result[:success] === false
            raise RuntimeError, result[:data]
          end

          match = result[:data]
        end

        previous_node = match
      end

      return previous_node if match == nil

      match
    end

    # If given a local file, the MD5 will be compared as well
    def exists?(remote_file, local_file = nil)
      if (file = find_by_path(remote_file)) == nil
        return {
            :success => false,
            :data => {
                "message" => "File #{remote_file} does not exist"
            }
        }
      end

      retval = {
          :success => true,
          :data => {
              "message" => "File #{remote_file} exists"
          }
      }

      if local_file != nil
        if file["contentProperties"] != nil && file["contentProperties"]["md5"] != nil
          if Digest::MD5.file(local_file).to_s != file["contentProperties"]["md5"]
            retval[:data]["message"] = "File #{remote_file} exists but checksum doesn't match"
          else
            retval[:data]["message"] = "File #{remote_file} exists and is identical"
          end
        else
          retval[:data]["message"] = "File #{remote_file} exists, but no checksum is available"
        end
      end

      retval
    end

    def fetch_metadata_by_id(id)
      RestClient.get("#{@account.metadata_url}nodes/id?fields=[\"properties\"]", :Authorization => "Bearer #{@account.access_token}") do |response, request, result|
        return JSON.parse(response.body) if response.code === 200
      end

      nil
    end

    def find_by_path(path)
      path = path.gsub(/\A\//, '')
      path = path.gsub(/\/$/, '')
      path_info = Pathname.new(path)

      found_nodes = {}
      @account.nodes.each do |id, node|
        if node["name"] == path_info.basename.to_s
          found_nodes[id] = node
        end
      end

      return nil if found_nodes.empty?

      match = nil
      found_nodes.each do |id, node|
        if build_node_path(node) == path
          match = node
        end
      end

      match
    end

    def get_metadata_by_id(id)
      return @account.nodes[id] if @account.nodes.has_key? id

      nil
    end

    def get_path_array(path)
      return path if path.kind_of?(Array)

      path = path.split('/')
      path.reject! do |value|
        value.empty?
      end

      path
    end

    def get_path_string(path)
      path = path.join '/' if path.kind_of?(Array)

      path.chomp
    end

    def get_root
      @account.nodes.each do |id, node|
        if node.has_key?('isRoot') && node['isRoot'] === true
          return node
        end
      end

      nil
    end

    def upload_dir(src_path, dest_root, show_progress = false)
      src_path = File.expand_path(src_path)

      dest_root = get_path_array(dest_root)
      dest_root.push(get_path_array(src_path).last)
      dest_root = get_path_string(dest_root)

      retval = []
      Find.find(src_path) do |file|
        # Skip root directory, no need to make it
        next if file == src_path || File.directory?(file)

        path_info = Pathname.new(file)
        remote_dest = path_info.dirname.sub(src_path, dest_root).to_s

        result = upload_file(file, remote_dest)
        if show_progress == true
          if result[:success] == true
            puts "Successfully uploaded file #{file}: #{result[:data].to_json}"
          else
            puts "Failed to uploaded file #{file}: #{result[:data].to_json}"
          end
        end

        retval.push(result)

        # Since uploading a directory can take a while (depending on number/size of files)
        # we will check if we need to renew our authorization after each file upload to
        # make sure our authentication doesn't expire.
        if (Time.new.to_i - @account.token_store["last_authorized"]) > 60
          result = @account.renew_authorization
          if result[:success] === false
            raise "Failed to renew authorization: #{result[:data].to_json}"
          end
        end
      end

      retval
    end

    def upload_file(src_path, dest_path)
      retval = {
          :success => false,
          :data => []
      }

      path_info = Pathname.new(src_path)
      dest_path = get_path_string(get_path_array(dest_path))
      dest_folder = create_directory_path(dest_path)

      result = exists?("#{dest_path}/#{path_info.basename}", src_path)
      if result[:success] == true
        retval[:data] = result[:data]

        return retval
      end

      body = {
          :metadata => {
              :kind => 'FILE',
              :name => path_info.basename,
              :parents => [
                  dest_folder["id"]
              ]
          }.to_json,
          :content => File.new(File.expand_path(src_path), 'rb')
      }

      RestClient.post("#{@account.content_url}nodes", body, :Authorization => "Bearer #{@account.access_token}") do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 201
          retval[:success] = true
          @account.update_node(retval[:data]["id"], retval[:data])
        end
      end

      retval
    end

  end

end
