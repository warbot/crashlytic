require 'ostruct'
require 'benchmark'
require File.join(File.expand_path(__dir__), '../app/config')

describe Config do
  it 'returns an instance of config parser' do
    config_parser = Config.new
    config = config_parser.load_config(config_parser.path_to_file)

    expect(config).to be_an_instance_of(Crashlytics)
  end

  it 'returns same config unless file changed' do
    config_parser = Config.new
    parser = double('parser', load_config: 'loads config')
    allow(Crashlytics).to receive(:new).and_return parser
    allow(config_parser).to receive(:file_changed?).and_return false

    config_parser.load_config(config_parser.path_to_file)
    config_parser.load_config(config_parser.path_to_file)

    expect(Crashlytics).to have_received(:new).once
  end

  it 'returns new config each time force_reload is true' do
    config_parser = Config.new
    parser = double('parser', load_config: 'loads config')
    allow(Crashlytics).to receive(:new).and_return parser
    allow(config_parser).to receive(:file_changed?).and_return false

    config_parser.load_config(config_parser.path_to_file)
    config_parser.load_config(config_parser.path_to_file, [], true)

    expect(Crashlytics).to have_received(:new).twice
  end

  it 'returns new config each time file changes' do
    config_parser = Config.new
    parser = double('parser', load_config: 'loads config')
    allow(Crashlytics).to receive(:new).and_return parser
    allow(config_parser).to receive(:file_changed?).and_return true

    config_parser.load_config(config_parser.path_to_file)
    config_parser.load_config(config_parser.path_to_file)

    expect(Crashlytics).to have_received(:new).twice
  end

  it 'works' do
    config_parser = Config.new

    config = config_parser.load_config(config_parser.path_to_file)

    expect(config.ftp.path).to eq '/tmp/'
  end
end