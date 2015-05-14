require 'bigdecimal'

module Applitools::Utils
  extend self

  def underscore(str)
    str.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr('-', '_').downcase
  end

  def symbolize_and_underscore_hash_keys(value, options = {})
    case value
    when Array
      value.map {|v| symbolize_and_underscore_hash_keys(v, options) }
    when Hash
      Hash[value.map {|k, v| [underscore(k.to_s).to_sym, symbolize_and_underscore_hash_keys(v, options)] }]
    else
      value
    end
  end
end


