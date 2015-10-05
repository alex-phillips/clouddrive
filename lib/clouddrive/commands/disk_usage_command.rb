module CloudDrive

  class DiskUsageCommand < Command

    parameter "[path]", "Config option to read, write, or reset"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
      @offline = true

      init

      if id?
        node = Node.load_by_id(path)
        if !node
          error("No node exists with ID '#{path}'")
          exit
        end
      else
        node = Node.load_by_path(path)
        if !node
          error("No node exists at path '#{path}'")
          exit
        end
      end

      puts format_filesize(calculate_total_size(node))
    end

    def calculate_total_size(node)
      size = node.get_size

      if node.is_folder
        node.get_children.each do |child|
          size += calculate_total_size(child)
        end
      end

      size
    end

  end

end
