require 'active_support/core_ext/hash/indifferent_access'
require 'ostruct'
require File.join(File.expand_path(__dir__), 'value_parser.rb')

class ConfigParser
  attr_reader :config, :prioritized_environments,
              :param_per_environment
  DEFAULT_ENV = '__default__'

  def initialize
    @groups = []
    @config = HashWithIndifferentAccess.new
    @param_per_environment = HashWithIndifferentAccess.new
    @prioritized_environments = [DEFAULT_ENV]
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
    before_parse
    parse_config(config)
    after_parse

    self
  end

  def parse_param(string)
    param_with_environment, value = string.split(params_regex)
    param, environment = param_with_environment.split(environment_tag_regex)

    [param, environment || DEFAULT_ENV, value]
  end

  def override?(group, param, env)
    @prioritized_environments.include?(env.to_s) &&
        @param_per_environment[group][param].has_key?(env)
  end

  def prioritized_environments=(overrides)
    @prioritized_environments = Array(overrides).map(&:to_s) + [DEFAULT_ENV]
    override_values
  end

  alias :environments= :prioritized_environments=

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
    @param_per_environment[group] ||= HashWithIndifferentAccess.new
    @param_per_environment[group][param] ||= HashWithIndifferentAccess.new
    @param_per_environment[group][param][environment] = @value_parser.parse(value)
    set_param_value_per_environment(group, param)
  end

  def set_param_value_per_environment(group, param, throw = false)
    @prioritized_environments.each do |env|
      if override?(group, param, env)
        @config[group][param] = @param_per_environment[group][param][env]
        throw ? throw(:stop) : break
      end
    end
  end

  def override_values
    catch(:stop) do
      @config.each do |group, param_values|
        param_values.to_h.keys.each do |param|
          set_param_value_per_environment(group, param, throw=true)
        end
      end
    end
  end

  def before_parse
  end

  def after_parse
    define_group_methods
  end

  def define_group_methods
    @groups.uniq.each do |group|
      return if respond_to?(group.to_sym)
      define_singleton_method(group) { @config[group] }
    end
  end

  def method_missing(*args)
    nil
  end
end
