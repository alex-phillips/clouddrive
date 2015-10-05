require 'fileutils'
require 'sequel'

module CloudDrive

  class Sqlite < Sql

    def initialize(email, cache_dir)
      # Strip of trailing slashes
      cache_dir = File.expand_path(cache_dir)

      if !File.exists?(cache_dir)
        FileUtils.mkdir_p(cache_dir)
      end

      if File.exists?("#{cache_dir}/#{email}.db")
        @db = Sequel.sqlite("#{cache_dir}/#{email}.db")
      else
        @db = Sequel.sqlite("#{cache_dir}/#{email}.db")
        @db.run(<<-SQL
        CREATE TABLE IF NOT EXISTS nodes(
          id VARCHAR PRIMARY KEY NOT NULL,
          name VARCHAR NOT NULL,
          kind VARCHAR NOT NULL,
          md5 VARCHAR,
          status VARCHAR,
          created DATETIME NOT NULL,
          modified DATETIME NOT NULL,
          raw_data TEXT NOT NULL
        );
        CREATE INDEX node_id on nodes(id);
        CREATE INDEX node_name on nodes(name);
        CREATE INDEX node_md5 on nodes(md5);
        SQL
        )
        @db.run(<<-SQL
        CREATE TABLE IF NOT EXISTS configs(
          id INTEGER PRIMARY KEY,
          email VARCHAR NOT NULL,
          token_type VARCHAR,
          expires_in INT,
          refresh_token TEXT,
          access_token TEXT,
          last_authorized INT,
          content_url VARCHAR,
          metadata_url VARCHAR,
          checkpoint VARCHAR
        );
        CREATE INDEX config_email on configs(email);
        SQL
        )
        @db.run(<<-SQL
        CREATE TABLE IF NOT EXISTS nodes_nodes(
          id INTEGER PRIMARY KEY,
          id_node VARCHAR NOT NULL,
          id_parent VARCHAR NOT NULL,
          UNIQUE (id_node, id_parent)
        );
        CREATE INDEX nodes_id_node on nodes_nodes(id_node);
        CREATE INDEX nodes_id_parent on nodes_nodes(id_parent);
        SQL
        )
      end
    end

  end

end