require 'yaml'

module CloudDrive

  class BaseCommand < ::Escort::ActionCommand::Base

    def initialize options, arguments
      super(options, arguments)
      @config_path = File.expand_path('~/.clouddrive') + "/"
    end

    def read_config
      if File.exists?("#{@config_path}config.yaml")
        return YAML.load_file("#{@config_path}config.yaml")
      else
        if !File.exists?(@config_path)
          Dir.mkdir(@config_path)
        end
      end

      {
          :email => nil,
          :client_id => nil,
          :client_secret => nil
      }
    end

    def save_config config
      if !File.exists?(@config_path)
        Dir.mkdir(@config_path)
      end

      File.open("#{@config_path}config.yaml", 'w') do |file|
        file.write(config.to_yaml)
      end
    end

  end

end
