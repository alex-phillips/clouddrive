module CloudDrive

  class ListPendingCommand < Command

    def execute
      @offline = true

      init
      list_nodes(Node.load_by_status('PENDING'))
    end

  end

end
