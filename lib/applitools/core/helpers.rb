module Applitools::Core
  module Helpers
    def abstract_attr_accessor(*names)
      names.each do |method_name|
        instance_variable_set "@#{method_name}", nil
        abstract_method method_name, true
        abstract_method "#{method_name}=", true
      end
    end

    def abstract_method(method_name, is_private = true)
      define_method method_name do |*_args|
        raise Applitools::AbstractMethodCalled.new method_name, self
      end
      private method_name if is_private
    end
  end
end
