describe Wordmove::SqlAdapter do
  let(:sql_path) { double }
  let(:source_config) { double }
  let(:dest_config) { double }
  let(:config_key) { double }
  let(:adapter) do
    Wordmove::SqlAdapter.new(
      sql_path,
      source_config,
      dest_config,
      config_key
    )
  end

  context ".initialize" do
    it "should assign variables correctly on initialization" do
      expect(adapter.sql_path).to eq(sql_path)
      expect(adapter.source_config).to eq(source_config)
      expect(adapter.dest_config).to eq(dest_config)
      expect(adapter.config_key).to eq(config_key)
    end
  end

  context ".sql_content" do
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write('DUMP')
        d.close
      end
    end
    let(:sql_path) { sql.path }

    it "should read the sql file content" do
      expect(adapter.sql_content).to eq('DUMP')
    end
  end

  context ".adapt!" do
    it "should replace host, path and write to sql" do
      expect(adapter).to receive(:replace_vhost!).and_return(true)
      expect(adapter).to receive(:replace_wordpress_path!).and_return(true)
      expect(adapter).to receive(:write_sql!).and_return(true)
      adapter.adapt!
    end
  end

  context ".replace_vhost!" do
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write(File.read(fixture_path_for('dump.sql')))
        d.close
      end
    end
    let(:sql_path) { sql.path }

    context "with port" do
      let(:source_config) { { vhost: 'localhost:8080' } }
      let(:dest_config) { { vhost: 'foo.bar:8181' } }

      it "should replace domain and port" do
        adapter.replace_vhost!
        adapter.write_sql!

        expect(File.read(sql)).to match('foo.bar:8181')
        expect(File.read(sql)).to_not match('localhost:8080')
      end
    end

    context "without port" do
      let(:source_config) { { vhost: 'localhost' } }
      let(:dest_config) { { vhost: 'foo.bar' } }

      it "should replace domain leving port unaltered" do
        adapter.replace_vhost!
        adapter.write_sql!

        expect(File.read(sql)).to match('foo.bar:8080')
        expect(File.read(sql)).to_not match('localhost:8080')
      end
    end
  end

  context ".write_sql!" do
    let(:content) { "THE DUMP!" }
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write(content)
        d.close
      end
    end
    let(:sql_path) { sql.path }
    let(:the_funk) { "THE FUNK THE FUNK THE FUNK" }

    it "should write content to file" do
      adapter.sql_content = the_funk
      adapter.write_sql!
      File.open(sql_path).read == the_funk
    end
  end
end
