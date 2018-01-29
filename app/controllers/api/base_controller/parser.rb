module Api
  class BaseController
    module Parser
      def parse_api_request
        @req = RequestAdapter.new(request, params)
      end

      def parse_id(resource, collection)
        return nil if !resource.kind_of?(Hash) || resource.blank?

        href_id = href_id(resource["href"], collection)
        case
        when href_id.present?
          href_id
        when resource["id"].kind_of?(Integer)
          resource["id"]
        when resource["id"].kind_of?(String)
          resource["id"].to_i
        end
      end

      def href_id(href, collection)
        if href.present? && href.match(%r{^.*/#{collection}/(\d+)$})
          Regexp.last_match(1).to_i
        end
      end

      def parse_by_attr(resource, type, attr_list = [])
        klass = collection_class(type)
        attr_list |= %w(guid) if klass.attribute_method?(:guid)
        attr_list |= String(collection_config[type].identifying_attrs).split(",")
        objs = attr_list.map { |attr| klass.find_by(attr => resource[attr]) if resource[attr] }.compact
        objs.collect(&:id).first
      end

      def parse_owner(resource)
        return nil if resource.blank?
        parse_id(resource, :users) || parse_by_attr(resource, :users)
      end

      def parse_group(resource)
        return nil if resource.blank?
        parse_id(resource, :groups) || parse_by_attr(resource, :groups)
      end

      def parse_role(resource)
        return nil if resource.blank?
        parse_id(resource, :roles) || parse_by_attr(resource, :roles)
      end

      def parse_tenant(resource)
        parse_id(resource, :tenants) unless resource.blank?
      end

      def parse_ownership(data)
        {
          :owner => collection_class(:users).find_by(:id => parse_owner(data["owner"])),
          :group => collection_class(:groups).find_by(:id => parse_group(data["group"]))
        }.compact if data.present?
      end

      # RBAC Aware type specific resource fetches

      def parse_fetch_group(data)
        if data
          group_id = parse_group(data)
          raise BadRequestError, "Missing Group identifier href, id or description" if group_id.nil?
          resource_search(group_id, :groups, collection_class(:groups))
        end
      end

      def parse_fetch_role(data)
        if data
          role_id = parse_role(data)
          raise BadRequestError, "Missing Role identifier href, id or name" if role_id.nil?
          resource_search(role_id, :roles, collection_class(:roles))
        end
      end

      def parse_fetch_tenant(data)
        if data
          tenant_id = parse_tenant(data)
          raise BadRequestError, "Missing Tenant identifier href or id" if tenant_id.nil?
          resource_search(tenant_id, :tenants, collection_class(:tenants))
        end
      end

      private

      def collection_option?(option)
        collection_config.option?(@req.collection, option) if @req.collection
      end

      def assert_id_not_specified(data, type)
        if data.key?('id') || data.key?('href')
          raise BadRequestError, "Resource id or href should not be specified for creating a new #{type}"
        end
      end

      def assert_all_required_fields_exists(data, type, required_fields)
        missing_fields = required_fields - data.keys
        unless missing_fields.empty?
          raise BadRequestError, "Resource #{missing_fields.join(", ")} needs be specified for creating a new #{type}"
        end
      end
    end
  end
end
