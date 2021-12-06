module Api
  module Mixins
    module ResourceApproveDeny
      def approve_resource(type, id, data)
        reason = data["reason"]
        api_resource(type, id, "Approving") do |resource|
          raise BadRequestError, "Must specify a reason for approving a #{type}" if reason.blank?

          resource.approve(User.current_userid, reason)
          {}
        end
      end

      def deny_resource(type, id, data)
        reason = data["reason"]
        api_resource(type, id, "Denying") do |resource|
          raise BadRequestError, "Must specify a reason for denying a #{type}" if reason.blank?

          resource.deny(User.current_userid, reason)
          {}
        end
      end
    end
  end
end
