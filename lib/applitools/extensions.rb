# @!visibility private
class Module
  def alias_attribute(new_name, old_name)
    module_eval <<-STR, __FILE__, __LINE__ + 1
      def #{new_name}
        self.#{old_name}
      end

      def #{new_name}?
        self.#{old_name}?
      end

      def #{new_name}=(v)
        self.#{old_name}
      end
    STR
  end
end
