module CloudDrive

  class FindCommand < Command

    parameter "name", "Config option to read, write, or reset"

    def execute
      init
      results = Node.search_by_name(name)
      list_nodes(results)
    end

  end

end
