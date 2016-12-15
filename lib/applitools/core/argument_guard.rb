module Applitools::Core
  module ArgumentGuard
    extend self
    def not_nil(param, param_name)
      raise Applitools::EyesIllegalArgument.new "#{param_name} is nil!" if param.nil?
    end

    def hash(param, param_name, required_fields = [])
      if param.is_a? Hash
        missed_keys = required_fields - param.keys
        error_message = "Expected #{param_name} to include keys #{missed_keys.join ', '}"
        raise Applitools::EyesIllegalArgument.new error_message if missed_keys.any?
      else
        error_message = "#{param_name} expected to be a Hash"
        end_of_message = required_fields.any? ? " containing keys #{required_fields.join(', ')}." : '.'
        error_message << end_of_message
        raise Applitools::EyesIllegalArgument.new error_message
      end
    end

    def greater_than_or_equal_to_zero(param, param_name)
      raise Applitools::EyesIllegalArgument.new "#{param_name} < 0" if 0 > param
    end

    def greater_than_zero(param, param_name)
      raise Applitools::EyesIllegalArgument.new "#{param_name} <= 0" if 0 >= param
    end

    def is_a?(param, param_name, klass)
      return true if param.is_a? klass
      raise Applitools::EyesIllegalArgument.new "Expected #{param_name} to be" \
        " instance of #{klass}"
    end
  end
end
