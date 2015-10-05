require 'clamp'
require 'colorize'

module CloudDrive

  class Command < Clamp::Command

    def read_config
      @default_config = {
          'email'             => {
              'type'    => 'string',
              'default' => '',
          },
          'client-id'         => {
              'type'    => 'string',
              'default' => '',
          },
          'client-secret'     => {
              'type'    => 'string',
              'default' => '',
          },
          'json.pretty'       => {
              'type'    => 'bool',
              'default' => false,
          },
          'upload.duplicates' => {
              'type'    => 'bool',
              'default' => false,
          },
          'database.driver'   => {
              'type'    => 'string',
              'default' => 'sqlite',
          },
          'database.database' => {
              'type'    => 'string',
              'default' => 'clouddrive_ruby',
          },
          'database.host'     => {
              'type'    => 'string',
              'default' => '127.0.0.1',
          },
          'database.username' => {
              'type'    => 'string',
              'default' => 'root',
          },
          'database.password' => {
              'type'    => 'string',
              'default' => '',
          },
          'display.trash'     => {
              'type'    => 'bool',
              'default' => false,
          },
      }

      @config = {}
      @cache_path = File.expand_path("~/.cache/clouddrive-ruby")
      if File.exists?(get_config_path)
        data = File.read(get_config_path)
        if data != ''
          set_config(JSON.parse(data))
        end
      end
    end

    def error(message)
      $stderr.puts "#{message}".colorize(:color => :white, :background => :red)
    end

    def format_filesize(bytes, decimals = 2)
      {
          'B'  => 1024,
          'KB' => 1024 * 1024,
          'MB' => 1024 * 1024 * 1024,
          'GB' => 1024 * 1024 * 1024 * 1024,
          'TB' => 1024 * 1024 * 1024 * 1024 * 1024
      }.each_pair { |e, s| return "#{(bytes.to_f / (s / 1024)).round(decimals)}#{e}" if bytes < s }
    end

    def get_config_path
      File.expand_path("#{@cache_path}/config.json");
    end

    def info(message)
      $stdout.puts "#{message}".green
    end

    def init
      read_config

      case @config["database.driver"]
        when "sqlite"
          cache = Sqlite.new(@config["email"], @cache_path)
        # when "mysql"
        else
          raise "Invalid database driver"
      end

      @account = Account.new(@config["email"], @config["client-id"], @config["client-secret"], cache)
      Node.init(@account, cache)
      if @offline === false
        response = @account.authorize
        if !response[:success]
          error("Failed to authorize account. Use `init` command for initial authorization.")
          exit
        end
      end
    end

    def list_nodes(nodes)
      nodes.each do |node|
        modified = Time.parse(node.data["modifiedDate"])
        if modified.year === Time.new().year
          modified = modified.strftime("%b %d %H:%M")
        else
          modified = modified.strftime("%b %d  %Y")
        end

        name = node.get_name
        if node.is_folder
          name = name.blue
        end

        puts "#{node.get_id}  #{modified}  #{node.get_status.ljust(10)} #{node.get_kind.ljust(7)} #{format_filesize(node.get_size, 0).ljust(6)}  #{name}"
      end
    end

    def save_config
      File.open(get_config_path, 'w') do |file|
        file.write(@config.to_json)
      end
    end

    def set_config(data)
      @default_config.each do |key, config|
        val = config['default']
        if data.has_key?(key)
          val = data[key]
        end

        set_config_value(key, val)
      end
    end

    def set_config_value(key, val)
      case @default_config[key]['type']
        when 'bool'
          val = val == 'true' ? true : false
        else
          val = val
      end

      @config[key] = val
    end

  end

end