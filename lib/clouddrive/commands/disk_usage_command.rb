module CloudDrive

  class DiskUsageCommand < Command

    parameter "[path]", "Config option to read, write, or reset"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
      @offline = true

      init

      if id?
        node = Node.load_by_id(path)
        unless node
          error("No node exists with ID '#{path}'")
        end
      else
        node = Node.load_by_path(path)
        unless node
          error("No node exists at path '#{path}'")
        end
      end

      @total_folders = 0
      @total_files = 0
      size = format_filesize(calculate_total_size(node))
      puts "#{@total_files} files, #{@total_folders} folders"
      puts size
    end

    def calculate_total_size(node)
      size = node.get_size

      if node.is_folder
        @total_folders += 1
        node.get_children.each do |child|
          size += calculate_total_size(child)
        end
      else
        @total_files += 1
      end

      size
    end

  end

end
