module CloudDrive

  class MoveCommand < Command

    parameter "node_path", "The remote node path to move"
    parameter "[new_path]", "Path to new parent node"

    def execute
      @offline = false

      init
      node = Node.load_by_path(node_path)
      unless node
        error("No node found at path '#{node_path}'")
        exit
      end

      new_parent = Node.load_by_path(new_path)
      unless new_parent
        error("No node found at path '#{new_path}'")
        exit
      end

      result = node.move(new_parent)
      if result[:success]
        info("Successfully moved node '#{node.get_name}' to '#{new_path}'")
      else
        error("Failed to move node '#{node.get_name}' to '#{new_path}': #{result[:data].to_json}")
      end
    end

  end

end
