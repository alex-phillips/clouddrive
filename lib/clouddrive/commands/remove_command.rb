module CloudDrive

  class RemoveCommand < Command

    parameter "remote_path", "Remote path of node to move to trash"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
      @offline = false

      init
      if id?
        node = Node.load_by_id(remote_path)
        unless node
          error("No node exists with ID '#{remote_path}'")
          exit
        end
      else
        node = Node.load_by_path(remote_path)
        unless node
          error("No node exists at path '#{remote_path}'")
          exit
        end
      end

      result = node.trash
      if result[:success]
        info("Successfully trashed '#{remote_path}'")
      else
        error("Failed to trash node: #{result[:data].to_json}")
      end
    end

  end

end
