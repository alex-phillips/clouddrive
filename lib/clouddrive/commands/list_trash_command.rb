module CloudDrive

  class ListTrashCommand < Command

    def execute
      @offline = true

      init
      list_nodes(Node.load_by_status('TRASH'), 'name', true, false)
    end

  end

end
