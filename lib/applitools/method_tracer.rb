# @!visibility private
module Applitools::MethodTracer
  def self.included(base)
    instance_methods = base.instance_methods(false) + base.private_instance_methods(false)
    class_methods = base.methods(false)

    base.class_eval do
      def self.trace_method(base, method_name, instance = true)
        original_method = instance ? instance_method(method_name) : method(method_name)

        send(instance ? :define_method : :define_singleton_method, method_name) do |*args, &block|
          Applitools::EyesLogger.debug "-> #{base}##{method_name}"
          return_value = (instance ? original_method.bind(self) : original_method).call(*args, &block)
          Applitools::EyesLogger.debug "<- #{base}##{method_name}"
          return_value
        end
      end

      instance_methods.each { |method_name| trace_method(base, method_name) }
      class_methods.each { |method_name| trace_method(base, method_name, false) }
    end
  end
end
