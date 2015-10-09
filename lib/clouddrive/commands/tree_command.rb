module CloudDrive

  class TreeCommand < Command

    parameter "[path]", "Path of node"
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

      puts node.get_name
      build_ascii_tree(node)
    end

    def build_ascii_tree(node, prefix = '')
      children = node.get_children
      count = children.count
      i = 0
      while i < count
        item_prefix = prefix
        child = children[i]

        unless child
          next
        end

        if i === (count - 1)
          if child.is_folder
            item_prefix += '└─┬ ';
          else
            if child.is_file
              item_prefix += '└── ';
            end
          end
        else
          if child.is_folder
            item_prefix += '├─┬ ';
          else
            if child.is_file
              item_prefix += '├── ';
            end
          end
        end

        name = child.get_name
        if child.is_folder
          name = name.blue
        end

        puts "#{item_prefix} #{name}"

        if child.is_folder
          if i == (count - 1)
            new_prefix = "#{prefix}  "
          else
            new_prefix = "#{prefix}| "
          end
          build_ascii_tree(child, new_prefix)
        end

        i+=1
      end
    end

  end

end