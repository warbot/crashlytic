class ValueParser
  def parse(value)
    typecast_value(value)
  end

  private

  def typecast_value(value)
    if value_string?(value)
      value.match(string_tag_regex)[1]
    elsif value_numeric?(value)
      value.to_i
    elsif value_array?(value)
      value.split(',')
    elsif value == 'yes'
      true
    elsif value == 'no'
      false
    else
      value
    end
  rescue
    nil
  end

  def value_string?(param)
    param.match(string_tag_regex)
  end

  def value_numeric?(param)
    param.match(numeric_tag_regex)
  end

  def value_array?(param)
    param.include?(',')
  end

  def string_tag_regex
    /^["'](.*)["']$/
  end

  def numeric_tag_regex
    /^\d+$/
  end
end