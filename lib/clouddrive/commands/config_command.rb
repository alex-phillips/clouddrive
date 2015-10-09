require 'colorize'

module CloudDrive

  class ConfigCommand < Command

    parameter "[option]", "Config option to read, write, or reset"
    parameter "[value]", "Value to set option to"

    def execute
      read_config
      if option
        unless @config.has_key?(option)
          error("Invalid option '#{option}'")
          exit
        end

        if value
          set_config_value(option, value)
          puts "#{option.blue} saved"
        else
          puts @config[option]
        end
      else
        max_width = 0
        @config.each do |key, value|
          if key.length > max_width
            max_width = key.length
          end
        end

        @config.each do |key, value|
          puts "#{key.ljust(max_width)} = #{value.to_s.blue}"
        end
      end

      save_config
    end

  end

end
