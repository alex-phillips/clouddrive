require 'rest-client'
require 'pathname'
require 'find'
require 'digest/md5'
require 'json'

module CloudDrive

  class Node

    attr_reader :data

    def self.init(account, cache)
      if defined?(@@initialized) && @@initialized == true
        raise "`Node` class already initialized"
      end

      @@initialized = true
      @@account = account
      @@cache = cache
    end

    def initialize(data)
      if !defined?(@@initialized) || !@@initialized
        raise "`Node` class must first be initialized"
      end

      @data = data
    end

    def self.create_new_folder(name, parent_id = nil)
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
          "#{@@account.metadata_url}nodes",
          body.to_json,
          :Authorization => "Bearer #{@@account.token_store[:access_token]}"
      ) do |response, request, result|
        data = JSON.parse(response.body)
        retval[:data] = data
        if response.code === 201
          retval[:success] = true
          retval[:data] = Node.new(data)
          retval[:data].save
        end
      end

      retval
    end

    def self.create_directory_path(path)
      retval = {
          :success => true,
          :data => {}
      }

      path = Node.get_path_array(path)
      previous_node = get_root

      match = nil
      path.each_with_index do |folder, index|
        xary = path.slice(0, index + 1)
        if (match = self.load_by_path(xary.join('/'))) === nil
          result = self.create_new_folder(folder, previous_node.get_id)
          if result[:success] === false
            return result
          end

          match = result[:data]
        end

        previous_node = match
      end

      if match == nil
        retval[:data] = previous_node
      else
        retval[:data] = match
      end

      retval
    end

    def delete
      @@cache.delete_node_by_id(get_id)
    end

    def download

    end

    def download_file(dest)

    end

    def download_folder(dest)

    end

    def filter(filters)
      @@cache.filterNodes(filters)
    end

    def get_children
      @@cache.find_nodes_by_parent_id(get_id)
    end

    def get_id
      @data['id']
    end

    def get_md5
      retval = nil
      if @data.has_key?('contentProperties') && @data['contentProperties'].has_key?('md5')
        retval = @data['contentProperties']['md5']
      end

      retval
    end

    def get_metadata
      # Request for metadata from API (also allow for generating public link)
    end

    def get_parent_ids
      @data['parents']
    end

    def get_path
      node = self
      path = []
      loop do
        path.push node.get_name

        break if node.is_root

        result = Node.load_by_id(node.get_parent_ids[0])
        if !result
          raise "No parent node found with ID #{node.get_parent_ids[0]}"
        end

        node = result

        break if node.is_root
      end

      path = path.reverse
      path.join('/')
    end

    def in_trash
      @data['status'] === 'TRASH'
    end

    def is_asset
      @data['kind'] === 'ASSET'
    end

    def is_file
      @data['kind'] === 'FILE'
    end

    def is_folder
      @data['kind'] === 'FOLDER'
    end

    def is_root
      return false if !@data.has_key?('isRoot')

      @data['isRoot'] ? true : false
    end

    def self.load_by_id(id)
      @@cache.find_node_by_id(id)
    end

    def self.load_by_md5(md5)
      @@cache.find_nodes_by_md5(md5)
    end

    def self.load_by_name(name)
      @@cache.find_nodes_by_name(name)
    end

    def self.load_by_path(path)
      if path.nil?
        path = '/'
      end

      path = path.gsub(/\A\//, '')
      path = path.gsub(/\/$/, '')

      if path == ''
        return get_root
      end

      path_info = Pathname.new(path)

      found_nodes = self.load_by_name(path_info.basename.to_s)
      if found_nodes.empty?
        return nil
      end

      match = nil
      found_nodes.each do |node|
        if node.get_path == path
          match = node
        end
      end

      match
    end

    def self.load_by_status(status)
      @@cache.find_nodes_by_status(status)
    end

    def self.load_root
      self.get_root
    end

    def move(new_parent)

    end

    def overwrite(local_path)
      retval = {
          :success => false,
          :data => {}
      }

      body = {
          :content => File.new(File.expand_path(local_path), 'rb')
      }

      RestClient.put("#{@@account.content_url}nodes/#{get_id}/content", body, :Authorization => "Bearer #{@@account.token_store[:access_token]}") do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
          node = Node.new(retval[:data])
          node.save
        end
      end

      retval
    end

    def rename(new_name)
      retval = {
          :success => false,
          :data => {}
      }

      RestClient.patch("#{@@account.metadata_url}nodes/#{get_id}", {:name => new_name}.to_json, :Authorization => "Bearer #{@@account.token_store[:access_token]}") do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
          @data = retval[:data]
          save
        end
      end

      retval
    end

    def restore
      retval = {
          :success => false,
          :data => {}
      }

      if get_status === 'AVAILABLE'
        retval[:data]["message"] = "Node is already available"

        return retval
      end

      RestClient.post("#{@@account.metadata_url}trash/#{get_id}/restore", {}, :Authorization => "Bearer #{@@account.token_store[:access_token]}") do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
          @data = retval[:data]
          save
        end
      end

      retval
    end

    def save
      if is_root
        @data['name'] = 'Cloud Drive'
      end

      @@cache.save_node(self)
    end

    def self.search_by_name(name)

    end

    def trash
      retval = {
          :success => false,
          :data => {}
      }

      if get_status === 'TRASH'
        retval[:data]["message"] = "Node is already in trash"

        return retval
      end

      RestClient.put("#{@@account.metadata_url}trash/#{get_id}", {}.to_json, :Authorization => "Bearer #{@@account.token_store[:access_token]}") do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 200
          retval[:success] = true
          @data = retval[:data]
          save
        end
      end

      retval
    end


    # If given a local file, the MD5 will be compared as well
    def self.exists?(remote_file, local_file = nil)
      if (file = Node.load_by_path(remote_file)) == nil
        if local_file != nil
          files = Node.load_by_md5(Digest::MD5.file(local_file).to_s)
          if !files.empty?
            ids = []
            files.each do |file|
              ids.push(file.get_id)
            end

            return {
                :success => true,
                :data => {
                    "message" => "File(s) exist with same MD5: #{ids.join(', ')}",
                    "path_match" => false,
                    "md5_match" => true
                }
            }
          end
        end

        return {
            :success => false,
            :data => {
                "message" => "File #{remote_file} does not exist",
                "path_match" => false,
                "md5_match" => false,
            }
        }
      end

      retval = {
          :success => true,
          :data => {
              "message" => "File #{remote_file} exists",
              "path_match" => true,
              "md5_match" => false,
              "node" => file,
          }
      }

      if local_file != nil
        md5 = file.get_md5
        if md5
          if Digest::MD5.file(local_file).to_s != md5
            retval[:data]["message"] = "File #{remote_file} exists but checksum doesn't match"
          else
            retval[:data]["message"] = "File #{remote_file} exists and is identical"
            retval[:data]["md5_match"] = true
          end
        else
          retval[:data]["message"] = "File #{remote_file} exists, but no checksum is available"
        end
      end

      retval
    end

    def get_kind
      @data['kind']
    end

    def get_name
      @data['name']
    end

    def self.get_path_array(path)
      return path if path.kind_of?(Array)

      path = path.split('/')
      path.reject! do |value|
        value.empty?
      end

      path
    end

    def self.get_path_string(path)
      path = path.join '/' if path.kind_of?(Array)

      path.chomp
    end

    def self.get_root
      results = load_by_name('Cloud Drive')

      if results.empty?
        raise "No node by the name of 'root' found in database"
      end

      results.each do |node|
        if node.data.has_key?("isRoot") && node.data["isRoot"] === true
          return node
        end
      end

      nil
    end

    def get_size
      retval = 0
      if @data.has_key?('contentProperties')
        if @data['contentProperties'].has_key?('size')
          retval = @data['contentProperties']['size']
        end
      end

      retval
    end

    def get_status
      @data["status"]
    end

    def self.upload_dir(src_path, dest_root, overwrite = false, callback = nil)
      src_path = File.expand_path(src_path)

      dest_root = Node.get_path_array(dest_root)
      dest_root.push(Node.get_path_array(src_path).last)
      dest_root = Node.get_path_string(dest_root)

      retval = []
      Find.find(src_path) do |file|
        # Skip root directory, no need to make it
        next if file == src_path || File.directory?(file)

        path_info = Pathname.new(file)
        remote_dest = path_info.dirname.sub(src_path, dest_root).to_s

        result = Node.upload_file(file, remote_dest, overwrite)
        unless callback.nil?
          callback.call(file, remote_dest, result)
        end

        retval.push(result)

        # Since uploading a directory can take a while (depending on number/size of files)
        # we will check if we need to renew our authorization after each file upload to
        # make sure our authentication doesn't expire.
        if (Time.new.to_i - @@account.token_store[:last_authorized]) > 60
          result = @@account.renew_authorization
          if result[:success] === false
            raise "Failed to renew authorization: #{result[:data].to_json}"
          end
        end
      end

      retval
    end

    def self.upload_file(src_path, dest_path, overwrite = false)
      retval = {
          :success => false,
          :data => {}
      }

      path_info = Pathname.new(src_path)
      dest_path = Node.get_path_string(Node.get_path_array(dest_path))

      dest_folder = Node.load_by_path(dest_path)
      if !dest_folder
        result = create_directory_path(dest_path)

        return result if result[:success] == false

        dest_folder = result[:data]
      end

      result = Node.exists?("#{dest_path}/#{path_info.basename}", src_path)
      if result[:success] == true
        if overwrite == false
          retval[:data] = result[:data]

          return retval
        end

        if result[:data]["md5_match"]
          retval[:data]["message"] = "Identical file already exists at #{dest_path}."

          return retval
        end

        return overwrite_file(src_path, result[:data]["node"])
      end

      body = {
          :metadata => {
              :kind => 'FILE',
              :name => path_info.basename,
              :parents => [
                  dest_folder.get_id
              ]
          }.to_json,
          :content => File.new(File.expand_path(src_path), 'rb')
      }

      RestClient.post("#{@@account.content_url}nodes", body, :Authorization => "Bearer #{@@account.token_store[:access_token]}") do |response, request, result|
        retval[:data] = JSON.parse(response.body)
        if response.code === 201
          retval[:success] = true
          Node.new(retval[:data]).save
        end
      end

      retval
    end

  end

end
