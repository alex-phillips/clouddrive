module CloudDrive

  class ListCommand < Command

    parameter "[path]", "Config option to read, write, or reset"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
      @offline = true

      init
      if id?
        node = Node.load_by_id(path)
        unless node
          error("No node exists with ID '#{path}'")
          exit
        end
      else
        node = Node.load_by_path(path)
        unless node
          error("No node exists at path '#{path}'")
          exit
        end
      end

      list_nodes(node.get_children, 'name', @config['show.trash'], @config['show.pending'])
    end

  end

end
