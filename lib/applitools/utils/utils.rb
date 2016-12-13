require 'bigdecimal'

module Applitools::Utils
  extend self

  def underscore(str)
    str.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').downcase
  end

  def uncapitalize(str)
    str[0, 1].downcase + str[1..-1]
  end

  def camelcase(str)
    tokens = str.split('_')
    uncapitalize(tokens.shift) + tokens.map(&:capitalize).join
  end

  def wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end

  def underscore_hash_keys(hash)
    convert_hash_keys(hash, :underscore)
  end

  def camelcase_hash_keys(hash)
    convert_hash_keys(hash, :camelcase)
  end

  def boolean_value(value)
    if value
      true
    else
      false
    end
  end

  def symbolize_keys(hash)
    hash.each_with_object({}) do |(k, v), memo|
      memo[k.to_sym] = v
    end
  end

  def extract_options!(array)
    return array.pop if array.last.instance_of? Hash
    {}
  end

  private

  def convert_hash_keys(value, method)
    case value
    when Array
      value.map { |v| convert_hash_keys(v, method) }
    when Hash
      Hash[value.map { |k, v| [send(method, k.to_s).to_sym, convert_hash_keys(v, method)] }]
    else
      value
    end
  end
end
