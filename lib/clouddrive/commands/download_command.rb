module CloudDrive

  class DownloadCommand < Command

    parameter "[remote_path]", "The remote node path to download"
    parameter "[local_path]", "Local path to save the file / folder to"
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

      unless local_path
        local_path = '.'
      end

      node.download(local_path)
      list_nodes(node.get_children, 'name', @config['show.trash'], @config['show.pending'])
    end

  end

end
