module Wordmove
  class SqlAdapter
    attr_accessor :sql_content
    attr_reader :sql_path, :source_config, :dest_config, :config_key

    def initialize(sql_path, source_config, dest_config, config_key)
      @sql_path = sql_path
      @source_config = source_config
      @dest_config = dest_config
      @config_key = config_key
    end

    def command
      wp_command = ""
      if config_key.present?
        origin = source_config[config_key]
        destination = dest_config[config_key]
        wp_command = "wp search-replace #{origin} #{destination} --all-tables"
      end
      wp_command
    end

    def sql_content
      @sql_content ||= File.open(sql_path).read
    end

    def write_sql!
      File.open(sql_path, 'w') { |f| f.write(sql_content) }
    end
  end
end
