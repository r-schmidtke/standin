module StandIn
  module Patches
    module CirclePatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do 
          unloadable
          before_validation :only_save_valid_proxy
        end
      end


      module InstanceMethods
      
        def only_save_valid_proxy
          if self.pref[:proxy_user_id] != 0
            if User.find(self.pref[:proxy_user_id]).pref[:proxy_user_id] != 0
              self.errors.add(:base, l('holidays.errors.invalid_proxy_user'))
              return false
            end
          end
        end

      end

    end
  end
end