module CloudDrive

  class RenameCommand < Command

    parameter "remote_path", "Remote path of node to rename"
    parameter "new_name", "New name for the node"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
      @offline = false

      init
      if id?
        node = Node.load_by_id(remote_path)
        if !node
          error("No node exists with ID '#{remote_path}'")
          exit
        end
      else
        node = Node.load_by_path(remote_path)
        if !node
          error("No node exists at path '#{remote_path}'")
          exit
        end
      end

      result = node.rename(new_name)
      if result[:success]
        info("Successfully renamed node to '#{new_name}'")
      else
        error("Failed to rename node: #{result[:data].to_json}")
      end
    end

  end

end
