module CloudDrive

  class MetadataCommand < Command

    parameter "[path]", "Config option to read, write, or reset"
    option ["-i", "--id"], :flag, "Designate remote node by ID"

    def execute
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

      puts node.data.inspect
    end

  end

end
