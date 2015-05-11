module Helpers
  def fixture_file_path(file_name)
    File.join(File.expand_path(__dir__), 'fixtures', file_name)
  end

  def touch(file_path)
    File.write(file_path, '')
    File.read(file_path)
  end

  def config_file
    File.read(config_file_path)
  end

  def config_file_path
    File.join(File.expand_path(__dir__), '../config/settings.conf')
  end
end