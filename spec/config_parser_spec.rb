require 'ostruct'
require 'benchmark'
require File.join(File.expand_path(__dir__), '../app/config_parser')

describe ConfigParser do
  xit 'saves groups' do
    parser = ConfigParser.new

    config = parser.parse(config_file)

    expect(config.groups).to match_array %w(common ftp http)
  end

  it 'defines config groups as methods' do
    parser = ConfigParser.new

    config = parser.parse(config_file)

    expect(config).to respond_to(:common)
  end

  it 'changes values based on environment' do
    parser = ConfigParser.new

    config = parser.parse(config_file, [:production, 'ubuntu'])

    expect(config.ftp[:path]).to eq '/srv/var/tmp/'

    config = parser.parse(config_file, ['ubuntu'])

    expect(config.prioritized_environments).not_to include 'production'
    expect(config.ftp[:path]).to eq '/etc/var/uploads'
  end

  describe 'assignment' do
    it 'returns numeric common paid_users_size_limit' do
      parser = ConfigParser.new

      config = parser.parse(config_file)

      expect(config.common.paid_users_size_limit).to eq 2147483648
    end

    it 'returns string ftp name' do
      parser = ConfigParser.new

      config = parser.parse(config_file)

      expect(config.ftp.name).to eq 'hello there, ftp uploading'
    end

    it 'returns array ftp params' do
      parser = ConfigParser.new

      config = parser.parse(config_file)

      expect(config.http.params).to eq %w(array of values)
    end

    it 'returns nil if there is no value set' do
      parser = ConfigParser.new

      config = parser.parse(config_file)

      expect(config.ftp.lastname).to be_nil
    end

    it 'returns yes/no for boolean stuff' do
      parser = ConfigParser.new

      config = parser.parse(config_file)

      expect(config.ftp.enabled).to eq false
    end

    it 'respects requested environment order' do
      parser = ConfigParser.new

      config = parser.parse(config_file, ['ubuntu', :production])

      expect(config.ftp[:path]).to eq '/etc/var/uploads'
    end

    it 'returns a hash for config group' do
      parser = ConfigParser.new

      config = parser.parse(config_file, ['ubuntu', :production])

      expected_result = {name: 'hello there, ftp uploading',
                         path: '/etc/var/uploads',
                         enabled: false}

      expect(config.ftp.to_h).to eq expected_result
    end
  end

  describe 'override_environments' do
    it 'are overwritten when file is loaded' do
      parser = ConfigParser.new

      config = parser.parse(config_file, ['ubuntu', :production])

      expect(config.prioritized_environments).to eq %w(ubuntu production __default__)

      config = parser.parse(config_file, ['macos', :dev, :new])

      expect(config.prioritized_environments).to eq %w(macos dev new  __default__)
    end
  end

  describe '#override?' do
    it 'overrides for production only because there is no option for other' do
      parser = ConfigParser.new
      config = parser.parse(config_file, ['ubuntu', :production])

      expect(config.override?(:http, :path, :production)).to be_truthy
      expect(config.override?(:http, :path, :ubuntu)).to be_falsey
      expect(config.override?(:http, :path, :weird_stuff)).to be_falsey
      expect(config.override?(:http, :path, :staging)).to be_falsey
    end

    it 'overrides for ubuntu as it is the last in the list' do
      parser = ConfigParser.new
      config = parser.parse(config_file, [:production, 'ubuntu'])

      expect(config.override?(:ftp, :path, :ubuntu)).to be_truthy
      expect(config.override?(:ftp, :path, :production)).to be_truthy
    end
  end

  describe '#prioritized_environments=' do
    it 'overrides values when config environment has changed' do
      crashlytics = ConfigParser.new
      param_per_environment = {http: {on: {'ubuntu' => 1, 'production' => 0}}}
      config = {http: {on: 0}}
      expected_config = {http: {on: 1}}
      crashlytics.instance_variable_set(:@param_per_environment, param_per_environment)
      crashlytics.instance_variable_set(:@config, config)

      crashlytics.environments = :ubuntu

      expect(crashlytics.config).to eq expected_config
    end
  end

  describe '#parsed_param' do
    it 'extracts the environment' do
      parser = ConfigParser.new
      parsed_param = %w(cool env mirimasu)

      expect(parser.parse_param('cool<env> = mirimasu')).to match_array parsed_param
    end

    it 'sets default environment unless present' do
      parser = ConfigParser.new
      parsed_param = %w(cool __default__ mirimasu)

      expect(parser.parse_param('cool = mirimasu')).to match_array parsed_param
    end
  end
end