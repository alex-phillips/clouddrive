module CloudDrive

  class ResolveCommand < Command

    parameter "id", "The ID of the node to resolve"

    def execute
      @offline = true

      init
      node = Node.load_by_id(id)
      if !node
        error("No node exists with ID '#{id}'")
      end

      puts node.get_path
    end

  end

end
