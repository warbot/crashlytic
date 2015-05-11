require 'ostruct'
require File.join(File.expand_path(__dir__), 'config_parser.rb')

class Crashlytics
  attr_reader :new_file, :file, :config_parser, :config

  def initialize
    @file = nil
    @new_file = true
    @config_parser = ConfigParser.new
    @config = OpenStruct.new
  end

  def path_to_file
    File.join(File.expand_path(__dir__), '../config/settings.conf')
  end

  def load_config(file_path, overrides = [])
    load_config_file(file_path)
    parse_config_or_change_config_environments(overrides)
    mark_file_old

    @config
  end

  def file_changed?(file)
    @file != file
  end

  private

  def parse_config_or_change_config_environments(overrides)
    if new_file
      @config = config_parser.parse(file, overrides)
    else
      @config
    end
  end

  def load_config_file(file_path, force_reload = false)
    file = File.read(file_path)

    if new_file || file_changed?(file) || force_reload
      @file = file
      mark_file_new
    end

    @file
  end

  def mark_file_old
    @new_file = false
  end

  def mark_file_new
    @new_file = true
  end
end
