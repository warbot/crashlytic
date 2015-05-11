require 'ostruct'
require 'benchmark'
require File.join(File.expand_path(__dir__), '../app/crashlytics')

describe Crashlytics do
  it 'works with valid config file' do
    crashlytics = Crashlytics.new

    config = crashlytics.load_config(crashlytics.path_to_file)

    expect(config.ftp.path).to eq '/tmp/'
  end

  it 'loads two different config files correctly' do
    crashlytics = Crashlytics.new
    path_to_config_file = crashlytics.path_to_file
    path_to_test_config_file = fixture_file_path('settings.conf')

    config = crashlytics.load_config(path_to_config_file, [:ubuntu, :production])

    expect(config.ftp.path).to eq '/etc/var/uploads'
    expect(config.ftp.name).to eq 'hello there, ftp uploading'

    config = crashlytics.load_config(path_to_test_config_file, [:ubuntu, :production])

    expect(config.ftp.path).to eq '/ftp/path/production'
    expect(config.ftp.name).to be_nil
  end

  describe '#load_config' do
    it 'reads a file' do
      crashlytics = Crashlytics.new
      path_to_config_file = crashlytics.path_to_file
      real_file = File.read(path_to_config_file)

      crashlytics.load_config(path_to_config_file)

      expect(crashlytics.file).to eq(real_file)
    end

    it 'returns an instance of config parser' do
      crashlytics = Crashlytics.new
      config = crashlytics.load_config(crashlytics.path_to_file)

      expect(config).to be_an_instance_of(crashlytics.config_parser)
    end

    it 'returns same config unless file changed' do
      crashlytics = Crashlytics.new
      config_parser = crashlytics.config_parser
      parser = double('parser', parse: crashlytics.config)
      allow(config_parser).to receive(:new).and_return parser
      allow(crashlytics).to receive(:file_changed?).and_return false

      crashlytics.load_config(crashlytics.path_to_file)
      crashlytics.load_config(crashlytics.path_to_file)

      expect(config_parser).to have_received(:new).once
    end

    it 'returns new config each time file changes' do
      crashlytics = Crashlytics.new
      config_parser = crashlytics.config_parser
      parser = double('parser', parse: crashlytics.config)
      allow(config_parser).to receive(:new).and_return parser
      allow(crashlytics).to receive(:file_changed?).and_return true

      crashlytics.load_config(crashlytics.path_to_file)
      crashlytics.load_config(crashlytics.path_to_file)

      expect(config_parser).to have_received(:new).twice
    end
  end

  describe '#file_changed?' do
    it 'is changed if the content has changed' do
      crashlytics = Crashlytics.new
      file_path = fixture_file_path('test.conf')
      touch(file_path)

      crashlytics.load_config(file_path)
      File.write(file_path, '1')
      file = File.read(file_path)

      expect(crashlytics.file_changed?(file)).to be_truthy
    end

    it 'is not changed unless the content has changed' do
      crashlytics = Crashlytics.new
      file_path = fixture_file_path('test.conf')
      touch(file_path)

      crashlytics.load_config(file_path)
      file = touch(file_path)

      expect(crashlytics.file_changed?(file)).to be_falsey
    end
  end

  describe 'design consideration' do
    it 'loads file fast as it would be load during boot' do
      times = (1..70_000)
      parser = Crashlytics.new
      file_path = fixture_file_path('test.conf')

      time = Benchmark.measure do
        times.each { parser.load_config(file_path) }
      end

      expect(time.total).to be < 1
    end
  end

end