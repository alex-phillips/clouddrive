module CloudDrive

  class Sql < Cache

    def delete_all_nodes
      @db.run("DELETE FROM nodes WHERE 1=1;")
    end

    def delete_node_by_id(id)
      @db.from(:nodes).where(:id => id).delete
      @db.from(:nodes_nodes).where(:id_node => id).delete
    end

    def find_node_by_id(id)
      retval = []
      results = @db.from(:nodes).select(:raw_data).where(:id => id).first

      return nil if !results

      Node.new(JSON.parse(results[:raw_data]))
    end

    def find_nodes_by_md5(md5)
      retval = []
      results = @db.from(:nodes).select(:raw_data).where(:md5 => md5).all
      results.each do |result|
        retval.push(Node.new(JSON.parse(result[:raw_data])))
      end

      retval
    end

    def find_nodes_by_parent_id(id)
      retval = []
      results = @db[:nodes].select(:raw_data).join(:nodes_nodes, :id_node => :id).where(:id_parent => id).all
      results.each do |result|
        retval.push(Node.new(JSON.parse(result[:raw_data])))
      end

      retval
    end

    def find_nodes_by_name(name)
      retval = []
      results = @db[:nodes].select(:raw_data).where(Sequel.ilike(:name, "%#{name}%")).all
      results.each do |result|
        retval.push(Node.new(JSON.parse(result[:raw_data])))
      end

      retval
    end

    def find_nodes_by_status(status)
      retval = []
      results = @db[:nodes].select(:raw_data).where(:status => status).all
      results.each do |result|
        retval.push(Node.new(JSON.parse(result[:raw_data])))
      end

      retval
    end

    def load_account_config(email)
      results = @db.from(:configs).where(:email => email).first

      return nil if !results

      results.to_hash
    end

    def save_account_config(account)
      dataset = @db[:configs]
      results = dataset.where(:email => account.email).first
      if !results
        dataset.insert(
            :email => account.email,
            :token_type => account.token_store[:token_type],
            :expires_in => account.token_store[:expires_in],
            :refresh_token => account.token_store[:refresh_token],
            :access_token => account.token_store[:access_token],
            :last_authorized => account.token_store[:last_authorized],
            :content_url => account.content_url,
            :metadata_url => account.metadata_url,
            :checkpoint => account.checkpoint
        )
      else
        dataset.where(:email => account.email).update(
            :token_type => account.token_store[:token_type],
            :expires_in => account.token_store[:expires_in],
            :refresh_token => account.token_store[:refresh_token],
            :access_token => account.token_store[:access_token],
            :last_authorized => account.token_store[:last_authorized],
            :content_url => account.content_url,
            :metadata_url => account.metadata_url,
            :checkpoint => account.checkpoint
        )
      end
    end

    def save_node(node)
      md5 = node.get_md5
      dataset = @db.from(:nodes)

      results = dataset.where(:id => node.get_id).first
      if !results
        dataset.insert(
            :id => node.get_id,
            :name => node.get_name,
            :kind => node.data["kind"],
            :md5 => md5,
            :status => node.data["status"],
            :created => node.data["createdDate"],
            :modified => node.data["modifiedDate"],
            :raw_data => node.data.to_json
        )
      else
        dataset.where(:id => node.get_id).update(
            :name => node.get_name,
            :kind => node.data["kind"],
            :md5 => md5,
            :status => node.data["status"],
            :created => node.data["createdDate"],
            :modified => node.data["modifiedDate"],
            :raw_data => node.data.to_json
        )
      end

      parent_ids = node.data['parents']
      previous_parents = @db.from(:nodes_nodes).where(:id_node => node.get_id).all
      previous_parents.each do |row|
        index = parent_ids.index(row[:id_parent])
        if index
          parent_ids.delete_at(index)
        else
          @db.from(:nodes_nodes).where(:id_parent => row[:id_parent], :id_node => node.get_id).delete
        end
      end

      parent_ids.each do |id|
        @db.from(:nodes_nodes).insert(
            :id_node => node.get_id,
            :id_parent => id
        )
      end
    end

  end

end