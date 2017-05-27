module Wordmove
  module Deployer
    class SSH < Base
      def initialize(environment, options)
        super
        ssh_options = remote_options[:ssh]
        @copier = Photocopier::SSH.new(ssh_options).tap { |c| c.logger = logger }
      end

      def push_db
        super

        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_gzipped_dump_path = local_dump_path + '.gz'
        local_gzipped_backup_path = local_wp_content_dir
                                    .path("#{environment}-backup-#{Time.now.to_i}.sql.gz")

        # Backup remote db
        download_remote_db(local_gzipped_backup_path)

        # Temporary backup local db
        save_local_db(local_dump_path)

        # search and replace some strings in local db
        run adapt_sql_command(local_options, remote_options, :vhost)
        run adapt_sql_command(local_options, remote_options, :wordpress_path)

        #dump adapted database
        local_search_replace_dump_path = local_wp_content_dir.path("search_replace_dump.sql")
        local_gzipped_search_replace_dump_path = local_search_replace_dump_path + '.gz'
        save_local_db(local_search_replace_dump_path)

        #push updated local db to remote db
        run compress_command(local_search_replace_dump_path)
        import_remote_dump(local_gzipped_search_replace_dump_path)
        local_delete(local_gzipped_search_replace_dump_path)

        #restore original local db
        run mysql_import_command(local_dump_path, local_options[:database])
        local_delete(local_dump_path)
      end

      def pull_db
        super

        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_gzipped_dump_path = local_dump_path + '.gz'
        local_backup_path = local_wp_content_dir.path("local-backup-#{Time.now.to_i}.sql")

        # Backup and compress local db
        save_local_db(local_backup_path)
        run compress_command(local_backup_path)

        # Download, uncompress and import remote db
        download_remote_db(local_gzipped_dump_path)
        run uncompress_command(local_gzipped_dump_path)
        run mysql_import_command(local_dump_path, local_options[:database])

        # Adapt local db
        run adapt_sql_command(remote_options, local_options, :vhost)
        run adapt_sql_command(remote_options, local_options, :wordpress_path)

        local_delete(local_dump_path)
      end

      private

      %w(get put get_directory put_directory delete).each do |command|
        define_method "remote_#{command}" do |*args|
          logger.task_step false, "#{command}: #{args.join(' ')}"
          @copier.send(command, *args) unless simulate?
        end
      end

      def remote_run(command)
        logger.task_step false, command
        unless simulate?
          _stdout, stderr, exit_code = @copier.exec! command
          raise(
            ShellCommandError,
            "Error code #{exit_code} returned by command \"#{command}\": #{stderr}"
          ) unless exit_code.zero?
        end
      end

      def download_remote_db(local_gizipped_dump_path)
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        # dump remote db into file
        remote_run mysql_dump_command(remote_options[:database], remote_dump_path)
        remote_run compress_command(remote_dump_path)
        remote_dump_path += '.gz'
        # download remote dump
        remote_get(remote_dump_path, local_gizipped_dump_path)
        remote_delete(remote_dump_path)
      end

      def import_remote_dump(local_gizipped_dump_path)
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        remote_gizipped_dump_path = remote_dump_path + '.gz'

        remote_put(local_gizipped_dump_path, remote_gizipped_dump_path)
        remote_run uncompress_command(remote_gizipped_dump_path)
        remote_run mysql_import_command(remote_dump_path, remote_options[:database])
        remote_delete(remote_dump_path)
      end
    end
  end
end
