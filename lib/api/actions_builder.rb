module Api
  class ActionsBuilder
    attr_reader :config, :href, :type, :cspec, :collection, :subcollection, :resource

    def initialize(request, href, type, resource = nil)
      @config = CollectionConfig.new
      @href = href
      @type = type
      @cspec = config[type]
      @collection = request.collection
      @subcollection = request.subcollection || (type.to_s if collection != type.to_s)
      @resource = resource
    end

    def actions
      return unless cspec
      targets = collection? ? collection_targets : subcollection_targets
      return [] unless targets
      targets.each.collect do |method, actions|
        next unless render_actions_for_method?(method)
        action_definitions(method, actions).each.collect do |action|
          next unless enabled_action?(action)
          actions = [{ 'name' => action[:name], 'method' => method, 'href' => href }]
          actions = gen_put_patch(actions) if action[:name] == 'edit' && !collection?
          actions
        end
      end.flatten.compact
    end

    private

    def collection?
      @is_collection ||= resource.nil?
    end

    def action_definitions(method, action_definitions)
      if collection?
        typed_subcollection_actions(method) || action_definitions
      else
        action_definitions || typed_subcollection_actions(method)
      end
    end

    def enabled_action?(action)
      !action[:disabled] && user_role_allows?(action[:identifier]) && action_validated?(action)
    end

    def collection_targets
      subcollection.nil? ? cspec[:collection_actions] : subcollection_actions
    end

    def subcollection_targets
      subcollection.nil? ? cspec[:resource_actions] : subresource_actions
    end

    def action_validated?(action_spec)
      return true if collection?
      if action_spec[:options] && action_spec[:options].include?(:validate_action)
        validate_method = "validate_#{action_spec[:name]}"
        return resource.respond_to?(validate_method) && resource.public_send(validate_method)
      end
      true
    end

    def gen_put_patch(actions)
      actions << { 'name' => 'edit', 'method' => :patch, 'href' => href } if cspec[:verbs].include?(:patch)
      actions << { 'name' => 'edit', 'method' => :put, 'href' => href } if cspec[:verbs].include?(:put)
      actions
    end

    def typed_subcollection_actions(method)
      return if subcollection.nil?
      config.typed_subcollection_action(collection, subcollection, method)
    end

    def subresource_actions
      cspec[:subresource_actions] || config.typed_subcollection_actions(collection, subcollection, :subresource)
    end

    def subcollection_actions
      cspec[:subcollection_actions] || config.typed_subcollection_actions(collection, subcollection)
    end

    def render_actions_for_method?(method)
      method != :get && cspec[:verbs].include?(method)
    end

    def user_role_allows?(action_identifier)
      return true unless action_identifier
      User.current_user.role_allows?(:identifier => action_identifier)
    end
  end
end
