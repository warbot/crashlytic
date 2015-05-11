require 'ostruct'
require File.join(File.expand_path(__dir__), 'value_parser.rb')

class ConfigParser
  attr_reader :config, :environments
  DEFAULT_ENV = '__default__'

  def initialize
    @groups = []
    @config = OpenStruct.new
    @environments = [DEFAULT_ENV]
    @value_parser = ValueParser.new
  end

  def params_regex
    /\s*=\s*/
  end

  def group_tag_regex
    /^\[(.*)\]$/
  end

  def environment_tag_regex
    /\b<(.+)>/
  end

  def comment_tag_regex
    /;.*/
  end

  def parse(config, environments = [])
    self.environments = environments
    parse_config(config)

    @config
  end

  def parse_param(string)
    param_with_environment, value = string.split(params_regex)
    param, environment = param_with_environment.split(environment_tag_regex)

    [param, environment || DEFAULT_ENV, value]
  end

  def override?(env)
    environment_present?(env)
  end

  def environments=(overrides)
    @environments = Array(overrides).map(&:to_s) + [DEFAULT_ENV]
  end

  def groups
    @groups.uniq
  end

  private

  def parse_config(config)
    config.each_line do |line|
      line = sanitize_line(line)
      next if line.empty?
      parse_line(line)
    end
  end

  def sanitize_line(line)
    line = line.strip
    line = remove_comment(line)
    line
  end

  def remove_comment(string)
    string.sub(comment_tag_regex, '')
  end

  def parse_line(line)
    if is_group_tag?(line)
      add_group_tag(group_tag(line))
    else
      add_param(line)
    end
  end

  def is_group_tag?(string)
    group_tag_regex.match(string)
  end

  def group_tag(string)
    group_tag_regex.match(string)[1]
  end

  def add_group_tag(group)
    @groups << group
    @config[group] = OpenStruct.new
  end

  def add_param(line)
    store_param(current_group, *parse_param(line))
  end

  def current_group
    @groups.last
  end

  def store_param(group, param, environment, value)
    if environment_present?(environment)
      @config[group][param] = @value_parser.parse(value)
    end
  end

  def environment_present?(environment)
    @environments.include?(environment.to_s)
  end
end
