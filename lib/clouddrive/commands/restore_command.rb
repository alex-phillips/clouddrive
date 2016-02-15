module CloudDrive

  class RestoreCommand < Command

    parameter "remote_path", "Remote path of node to move to restore"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
      @offline = false

      init
      if id?
        node = Node.load_by_id(remote_path)
        unless node
          error("No node exists with ID '#{remote_path}'")
        end
      else
        node = Node.load_by_path(remote_path)
        unless node
          error("No node exists at path '#{remote_path}'")
        end
      end

      result = node.restore
      if result[:success]
        info("Successfully restored '#{remote_path}'")
      else
        error("Failed to restore node: #{result[:data].to_json}")
      end
    end

  end

end
