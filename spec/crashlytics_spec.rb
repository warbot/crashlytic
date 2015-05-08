require 'set'
require 'ostruct'
require 'benchmark'
require File.join(File.expand_path(__dir__), '../app/crashlytics')

describe Crashlytics do
  it 'saves groups' do
    crashlytics = Crashlytics.new
    path_to_config_file = crashlytics.path_to_file

    config = crashlytics.load_config(path_to_config_file)

    expect(config.groups).to match_array %w(common ftp http)
  end

  it 'defines config groups as methods' do
    crashlytics = Crashlytics.new
    path_to_config_file = crashlytics.path_to_file

    config = crashlytics.load_config(path_to_config_file)

    expect(config).to respond_to(:common)
  end

  it 'always has __default__ key' do
    crashlytics = Crashlytics.new
    path_to_config_file = crashlytics.path_to_file

    config = crashlytics.load_config(path_to_config_file, ['ubuntu', :production])

    expect(config.override?(:http, :path, :__default__)).to be_truthy
  end

  it 'returns overloaded params based on env' do
    crashlytics = Crashlytics.new
    path_to_config_file = crashlytics.path_to_file

    config = crashlytics.load_config(path_to_config_file, [:production, 'ubuntu'])

    expect(config.ftp[:path]).to eq '/srv/var/tmp/'
  end

  it 'changes values based on environment but does not reload the file' do
    crashlytics = Crashlytics.new
    path_to_config_file = crashlytics.path_to_file

    config = crashlytics.load_config(path_to_config_file, [:production, 'ubuntu'])

    expect(config.ftp[:path]).to eq '/srv/var/tmp/'

    config = crashlytics.load_config(path_to_config_file, ['ubuntu'])

    expect(config.prioritized_environments).to eq %w(__default__ ubuntu)
    expect(config.ftp[:path]).to eq '/etc/var/uploads'
  end

  describe 'assignment' do
    it 'returns numeric common paid_users_size_limit' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file)

      expect(config.common.paid_users_size_limit).to eq 2147483648
    end

    it 'returns string ftp name' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file)

      expect(config.ftp.name).to eq 'hello there, ftp uploading'
    end

    it 'returns array ftp params' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file)

      expect(config.http.params).to eq %w(array of values)
    end

    it 'returns nil if there is no value set' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file)

      expect(config.ftp.lastname).to be_nil
    end

    it 'returns yes/no for boolean stuff' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file)
      
      expect(config.ftp.enabled).to eq false
    end

    it 'respects requested environment order for multiple options' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file, ['ubuntu', :production])

      expect(config.ftp[:path]).to eq '/etc/var/uploads'
    end

    it 'returns a hash for config group' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file, ['ubuntu', :production])

      expected_result = {name: 'hello there, ftp uploading',
                       path: '/etc/var/uploads',
                       enabled: false}

      expect(config.ftp.to_h).to eq expected_result
    end
  end

  describe 'override_environments' do
    it 'are overwritten when file is loaded' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file, ['ubuntu', :production])

      expected_envs = %w(__default__ production ubuntu)
      expect(config.prioritized_environments).to eq expected_envs

      config = crashlytics.load_config(path_to_config_file, ['macos', :dev])

      expected_envs = %w(__default__ dev macos)
      expect(config.prioritized_environments).to eq expected_envs
    end
  end

  describe '#override?' do
    it 'overrides for production only because there is no option for other' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file
      config = crashlytics.load_config(path_to_config_file, ['ubuntu', :production])

      expect(config.override?(:http, :path, :production)).to be_truthy
      expect(config.override?(:http, :path, :ubuntu)).to be_falsey
      expect(config.override?(:http, :path, :weird_stuff)).to be_falsey
      expect(config.override?(:http, :path, :staging)).to be_falsey
    end

    it 'overrides for ubuntu as it is the last in the list' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file
      config = crashlytics.load_config(path_to_config_file, [:production, 'ubuntu'])
      
      expect(config.override?(:ftp, :path, :ubuntu)).to be_truthy
      expect(config.override?(:ftp, :path, :production)).to be_truthy
    end
  end

  describe '#parsed_param' do
    it 'extracts the environment' do
      crashlytics = Crashlytics.new
      parsed_param = %w(cool env mirimasu)

      expect(crashlytics.parse_param('cool<env> = mirimasu')).to match_array parsed_param
    end

    it 'sets default environment unless present' do
      crashlytics = Crashlytics.new
      parsed_param = %w(cool __default__ mirimasu)

      expect(crashlytics.parse_param('cool = mirimasu')).to match_array parsed_param
    end
  end

  describe 'design consideration' do
    it 'loads file fast as it would be load during boot' do
      times = (1..3000)
      crashlytics = Crashlytics.new
      file_path = crashlytics.path_to_file

      time = Benchmark.measure do
        times.each { crashlytics.load_config(file_path) }
      end

      expect(time.total).to be < 1
    end
  end

  describe '#load_config_file' do
    it 'loads file' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file
      real_file = File.read(path_to_config_file)

      file = crashlytics.load_config_file(path_to_config_file)

      expect(real_file).to eq(file)
    end

    it 'does not load the file 2nd time unless modification time has changed' do
      crashlytics = Crashlytics.new
      file = double 'file'
      path_to_config_file = crashlytics.path_to_file
      allow(File).to receive(:read).and_return(file)
      allow(crashlytics).to receive(:file_changed?).and_return false

      crashlytics.load_config_file(path_to_config_file)
      crashlytics.load_config_file(path_to_config_file)

      expect(File).to have_received(:read).once
    end

    it 'loads the file anytime with force_reload' do
      crashlytics = Crashlytics.new
      file = double 'file'
      path_to_config_file = crashlytics.path_to_file
      allow(File).to receive(:read).and_return(file)
      allow(crashlytics).to receive(:file_changed?).and_return false

      crashlytics.load_config_file(path_to_config_file)
      crashlytics.load_config_file(path_to_config_file, true)

      expect(File).to have_received(:read).twice
    end

    it 'reloads the file if file modification time has changed' do
      crashlytics = Crashlytics.new
      file = double 'file'
      path_to_config_file = crashlytics.path_to_file
      allow(File).to receive(:read).and_return(file)
      allow(crashlytics).to receive(:file_changed?).and_return true

      crashlytics.load_config_file(path_to_config_file)
      crashlytics.load_config_file(path_to_config_file)

      expect(File).to have_received(:read).twice
    end
  end

  describe 'new_file' do
    it 'is new by default' do
      crashlytics = Crashlytics.new

      expect(crashlytics.new_file).to be_truthy
    end

    it 'is marked as old after being parsed' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file

      config = crashlytics.load_config(path_to_config_file)

      expect(config.new_file).to be_falsey
    end

    it 'is marked as new after file being changed' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file
      crashlytics.load_config(path_to_config_file)
      allow(crashlytics).to receive(:file_changed?).and_return true

      crashlytics.load_config_file(path_to_config_file)

      expect(crashlytics.new_file).to be_truthy
    end
  end

  describe '#prioritized_environments=' do
    it 'overrides values when config environment has changed' do
      crashlytics = Crashlytics.new
      ppe = {http:{on:{'ubuntu' => 1, 'production' => 0}}}
      config = {http: {on: 0}}
      expected_config = {http: {on: 1}}
      crashlytics.instance_variable_set(:@param_per_environment, ppe)
      crashlytics.instance_variable_set(:@config, config)

      crashlytics.environments = :ubuntu

      expect(crashlytics.config).to eq expected_config
    end
  end

end