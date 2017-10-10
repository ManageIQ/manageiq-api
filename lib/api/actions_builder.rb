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

    def collection_actions
      return unless cspec
      targets = subcollection.nil? ? cspec[:collection_actions] : subcollection_actions
      return [] unless targets
      targets.each.collect do |method, action_definitions|
        next unless render_actions_for_method?(method)
        action_defs = typed_subcollection_actions(method) || action_definitions
        action_defs.each.collect do |action|
          next unless !action[:disabled] && user_role_allows?(action[:identifier])
          { 'name' => action[:name], 'method' => method, 'href' => href }
        end
      end.flatten.compact
    end

    def resource_actions
      targets = subcollection.nil? ? cspec[:resource_actions] : subresource_actions
      return [] unless targets
      targets.each.collect do |method, action_definitions|
        next unless render_actions_for_method?(method)
        action_defs = action_definitions || typed_subcollection_actions(method)
        action_defs.each.collect do |action|
          next unless !action[:disabled] && user_role_allows?(action[:identifier]) && action_validated?(action)
          actions = [{ 'name' => action[:name], 'method' => method, 'href' => href }]
          actions = gen_put_patch(actions) if action[:name] == 'edit'
          actions
        end
      end.flatten.compact
    end

    private

    def action_validated?(action_spec)
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
