module CloudDrive

  class MkdirCommand < Command

    parameter "remote_path", "Path of node"

    def execute
      @offline = false

      init
      if Node.exists?(remote_path)[:success]
        error("Node already exists at '#{remote_path}'")
        exit
      end

      result = Node.create_directory_path(remote_path)
      if result[:success]
        info("Successfully created remote path '#{remote_path}'")
      else
        error("Failed to create remote path '#{remote_path}': #{result[:data].to_json}")
      end
    end

  end

end