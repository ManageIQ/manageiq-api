require 'jbuilder'

module Api
  class BaseController
    module Renderer
      #
      # Helper proc to render a collection
      #
      def render_collection(type, resources, opts = {})
        render :json => collection_to_jbuilder(type, gen_reftype(type, opts), resources, opts).target!
      end

      #
      # Helper proc to render a single resource
      #
      def render_resource(type, resource, opts = {})
        render :json => resource_to_jbuilder(type, gen_reftype(type, opts), resource, opts).target!, :status => status_from_resource(resource)
      end

      #
      # We want reftype to reflect subcollection if targeting as such.
      #
      def gen_reftype(type, opts)
        opts[:is_subcollection] ? "#{@req.collection}/#{@req.collection_id}/#{type}" : type
      end

      # Methods for Serialization as Jbuilder Objects.

      #
      # Given a resource, return its serialized flavor using Jbuilder
      #
      def collection_to_jbuilder(type, reftype, resources, opts = {})
        link_builder = Api::LinksBuilder.new(params, @req.url, opts[:counts])
        Jbuilder.new do |json|
          json.set! 'name', opts[:name] if opts[:name]

          if opts[:counts]
            opts[:counts].counts.each do |count, value|
              json.set! count, value
            end
          end

          json.set! 'pages', link_builder.pages if link_builder.links?

          unless @req.hide?("resources") || collection_option?(:hide_resources)
            key_id = collection_config.resource_identifier(type)
            json.resources resources.collect do |resource|
              if opts[:expand_resources]
                add_hash json, resource_to_jbuilder(type, reftype, resource, opts).attributes!
              else
                json.href normalize_href(reftype, resource[key_id])
              end
            end
          end
          cspec = collection_config[type]
          aspecs = gen_action_spec_for_collections(type, cspec, opts[:is_subcollection], reftype) if cspec
          add_actions(json, aspecs, reftype)

          if link_builder.links?
            json.links do
              link_builder.links.each do |link_name, link_href|
                json.set! link_name, link_href
              end
            end
          end
        end
      end

      def resource_to_jbuilder(type, reftype, resource, opts = {})
        normalize_options = {}
        reftype = get_reftype(type, reftype, resource, opts)
        json    = Jbuilder.new

        physical_attrs, virtual_attrs = validate_attr_selection(resource)
        normalize_options[:render_attributes] = physical_attrs if physical_attrs.present?

        add_hash json, normalize_hash(reftype, resource, normalize_options)

        expand_virtual_attributes(json, type, resource, virtual_attrs) unless virtual_attrs.empty?
        expand_subcollections(json, type, resource) if resource.respond_to?(:attributes)
        json.set!('href_slug', "#{type}/#{resource.id}") if virtual_attrs.include?('href_slug')

        expand_actions(resource, json, type, opts, physical_attrs) if opts[:expand_actions]
        expand_resource_custom_actions(resource, json, type, physical_attrs) if opts[:expand_custom_actions]
        json
      end

      def get_reftype(type, reftype, resource, _opts = {})
        # sometimes we are returning different objects than the posted resource, i.e. request for an order.
        return reftype unless resource.respond_to?(:attributes)

        rclass = resource.class
        collection_class = collection_class(type)

        # Ensures hrefs are consistent with those of the collection they were requested from
        return reftype if collection_class == rclass || collection_class.descendants.include?(rclass)

        collection_config.name_for_klass(rclass) || collection_config.name_for_subclass(rclass)
      end

      #
      # Common proc for adding a child element to the Jbuilder
      #
      def add_child(json, hash)
        json.child! { |js| hash.each { |attr, value| js.set! attr, value } } unless hash.blank?
      end

      #
      # Common proc for adding a hash directly to the Jbuilder
      #
      def add_hash(json, hash)
        return if hash.blank?
        hash.each do |attr, value|
          json.set! attr, value
        end
      end

      #
      # Method name for optional accessor of virtual attributes
      #
      def virtual_attribute_accessor(type, attr)
        method = "fetch_#{type}_#{attr}"
        respond_to?(method) ? method : nil
      end

      private

      def resource_search(id, type, klass = nil, key_id = nil)
        klass  ||= collection_class(type)
        key_id ||= collection_config.resource_identifier(type)
        validate_id(id, key_id, klass)
        target =
          if respond_to?("find_#{type}")
            public_send("find_#{type}", id)
          else
            find_resource(klass, key_id, id)
          end
        raise NotFoundError, "Couldn't find #{klass} with '#{key_id}'=#{id}" unless target
        filter_resource(target, type, klass)
      end

      def find_resource(klass, key_id, id)
        key_id == "id" ? klass.find(id) : klass.find_by(key_id => id)
      end

      def filter_resource(target, type, klass)
        res = Rbac.filtered_object(target, :user => User.current_user, :class => klass)
        raise ForbiddenError, "Access to the resource #{type}/#{target.id} is forbidden" unless res
        res
      end

      def collection_search(is_subcollection, type, klass)
        res =
          if is_subcollection
            send("#{type}_query_resource", parent_resource_obj)
          elsif by_tag_param
            klass.find_tagged_with(:all => by_tag_param, :ns => TAG_NAMESPACE, :separator => ',')
          else
            find_collection(klass)
          end

        res = res.where(public_send("#{type}_search_conditions")) if respond_to?("#{type}_search_conditions")
        collection_filterer(res, type, klass, is_subcollection)
      end

      def find_collection(klass)
        klass.all
      end

      def collection_filterer(res, type, klass, is_subcollection = false)
        miq_expression = filter_param(klass)

        if miq_expression
          if is_subcollection && !res.respond_to?(:where)
            raise BadRequestError, "Filtering is not supported on #{type} subcollection"
          end
          sql, _, attrs = miq_expression.to_sql
          res = res.where(sql) if attrs[:supported_by_sql]
        end

        sort_options = sort_params(klass) if res.respond_to?(:reorder)
        res = res.reorder(sort_options) if sort_options.present?

        options = {:user => User.current_user}
        options[:order] = sort_options if sort_options.present?
        options[:filter] = miq_expression if miq_expression
        options[:offset] = integer_param('offset') if params['offset']
        options[:limit] = integer_param('limit') if params['limit']
        options[:extra_cols] = determine_extra_cols(klass)
        options[:include_for_find] = determine_include_for_find(klass)

        filter_results(miq_expression, res, options)
      end

      def filter_results(miq_expression, res, options)
        if miq_expression.present? && options.key?(:limit) && options.key?(:offset)
          subquery_res = Rbac.filtered(res, options.except(:offset, :limit, :extra_cols))
          [Rbac.filtered(res, options), subquery_res.count]
        else
          [Rbac.filtered(res, options)]
        end
      end

      def virtual_attribute_search(resource, attribute)
        if resource.class < ApplicationRecord
          rbac = Rbac::Filterer.new
          # is relation in 'attribute' variable plural in the model class (from 'resource.class') ?
          if [:has_many, :has_and_belongs_to_many].include?(resource.class.reflection_with_virtual(attribute).try(:macro))
            resource_attr = resource.public_send(attribute)
            klass         = resource_attr.kind_of?(ActiveRecord::Relation) ? resource_attr.klass : resource_attr.try(:first).class
            return resource_attr unless rbac.send(:apply_rbac_directly?, klass)
            Rbac.filtered(resource_attr)
          # Don't re-do an Rbac query if it has already been done
          elsif collection_class(@req.subject) != resource.class.base_model && rbac.send(:apply_rbac_directly?, resource.class)
            Rbac.filtered_object(resource).try(:public_send, attribute)
          else
            resource.public_send(attribute)
          end
        else
          resource.public_send(attribute)
        end
      end

      #
      # Let's expand subcollections for objects if asked for
      #
      def expand_subcollections(json, type, resource)
        collection_config.subcollections(type).each do |sc|
          target = "#{sc}_query_resource"
          next unless expand_subcollection?(sc, target)
          if Array(attribute_selection).include?(sc.to_s)
            raise BadRequestError, "Cannot expand subcollection #{sc} by name and virtual attribute"
          end
          expand_subcollection(json, sc, "#{type}/#{resource.id}/#{sc}", send(target, resource))
        end
      end

      def expand_subcollection?(sc, target)
        return false unless respond_to?(target) # If there's no query method, no need to go any further
        expand_resources?(sc) || expand_action_resource?(sc) || resource_requested?(sc)
      end

      # Expand if: expand='resources' && no attributes specified && subcollection is configured
      def expand_resources?(sc)
        collection_config.show?(sc) && (@req.collection_id || @req.expand?('resources')) && @req.attributes.empty?
      end

      # Expand if: resource is being returned and subcollection is configured
      # IE an update to /service_catalogs expects service_templates as part of its resource
      def expand_action_resource?(sc)
        @req.method != :get && collection_config.show?(sc)
      end

      # Expand if: explicitly requested
      def resource_requested?(sc)
        @req.expand?(sc)
      end

      #
      # Let's expand virtual attributes and related objects if asked for
      # Supporting [<related_object>]*.<virtual_attribute>
      #
      def expand_virtual_attributes(json, type, resource, virtual_attrs)
        result = {}
        object_hash = {}
        virtual_attrs.each do |vattr|
          next if vattr == 'href_slug'
          attr_name, attr_base = split_virtual_attribute(vattr)
          value, value_result = if attr_base.blank?
                                  fetch_direct_virtual_attribute(type, resource, attr_name)
                                else
                                  fetch_indirect_virtual_attribute(type, resource, attr_base, attr_name, object_hash)
                                end
          result = result.deep_merge(Hash(value_result))
        end
        add_hash json, result
      end

      def fetch_direct_virtual_attribute(type, resource, attr)
        return unless attr_accessible?(resource, attr)

        virtattr_accessor = virtual_attribute_accessor(type, attr)
        value = virtattr_accessor ? send(virtattr_accessor, resource) : virtual_attribute_search(resource, attr)
        value = add_custom_action_hrefs(value) if attr == "custom_actions"
        result = {attr => normalize_attr(attr, value)}
        # set nil vtype above to "#{type}/#{resource.id}/#{attr}" to support id normalization
        [value, result]
      end

      #
      # HACK: Because custom actions are represented as a plain hash
      # in the model, we lose all context about the type of object we
      # must add an href to in the normalization process. Refactoring
      # all of normalization to get the proper context will be
      # necessary in order to fix this correctly. Instead, we
      # intercept the result here, adding the correct hrefs, which
      # will not be overwritten later.
      #
      def add_custom_action_hrefs(value)
        return if value.nil?
        result = value.dup
        result[:buttons].each do |button|
          button["href"] = normalize_href(:custom_buttons, button["id"])
        end
        result[:button_groups].each do |group|
          group["href"] = normalize_href(:custom_button_sets, group["id"])
          group[:buttons].each do |button|
            button["href"] = normalize_href(:custom_buttons, button["id"])
          end
        end
        result
      end

      def fetch_indirect_virtual_attribute(_type, resource, base, attr, object_hash)
        query_related_objects(base, resource, object_hash)
        return unless attr_accessible?(object_hash[base], attr)
        value  = virtual_attribute_search(object_hash[base], attr)
        result = {attr => normalize_attr(attr, value)}
        # set nil vtype above to "#{type}/#{resource.id}/#{base.tr('.', '/')}/#{attr}" to support id normalization
        base.split(".").reverse_each { |level| result = {level => result} }
        [value, result]
      end

      #
      # Accesing and hashing <resource>[.<related_object>]+ in object_hash
      #
      def query_related_objects(object_path, resource, object_hash)
        return if object_hash[object_path].present?
        related_resource = resource
        related_objects  = []
        object_path.split(".").each do |related_object|
          related_objects << related_object
          if attr_accessible?(related_resource, related_object)
            related_resource = related_resource.public_send(related_object)
            object_hash[related_objects.join(".")] = related_resource if related_resource
          end
        end
      end

      def split_virtual_attribute(attr)
        attr_parts = attr_split(attr)
        return [attr_parts.first, ""] if attr_parts.length == 1
        [attr_parts.last, attr_parts[0..-2].join(".")]
      end

      def attr_accessible?(object, attr)
        return true if object && object.respond_to?(attr)
        object.class.try(:has_attribute?, attr) ||
          object.class.try(:reflect_on_association, attr) ||
          object.class.try(:virtual_attribute?, attr) ||
          object.class.try(:virtual_reflection?, attr)
      end

      def attr_virtual?(object, attr)
        return false if ID_ATTRS.include?(attr)
        primary = attr_split(attr).first
        klass   = object
        klass   = object.class if object.kind_of?(ActiveRecord::Base)
        (klass.respond_to?(:reflect_on_association) && klass.reflect_on_association(primary)) ||
          (klass.respond_to?(:virtual_attribute?) && klass.virtual_attribute?(primary)) ||
          (klass.respond_to?(:virtual_reflection?) && klass.virtual_reflection?(primary))
      end

      def attr_physical?(object, attr)
        return true if ID_ATTRS.include?(attr)
        klass = object
        klass = object.class if object.kind_of?(ActiveRecord::Base)
        (klass.respond_to?(:has_attribute?) && klass.has_attribute?(attr)) &&
          !(klass.respond_to?(:virtual_attribute?) && klass.virtual_attribute?(attr))
      end

      def attr_split(attr)
        attr.tr("/", ".").split(".")
      end

      #
      # Let's expand actions
      #
      def expand_actions(resource, json, type, opts, physical_attrs)
        return unless render_actions(physical_attrs)

        href = json.attributes!["href"]
        cspec = collection_config[type]
        aspecs = gen_action_spec_for_resources(cspec, opts[:is_subcollection], href, resource) if cspec
        add_actions(json, aspecs, type)
      end

      def add_actions(json, aspecs, type)
        if aspecs && aspecs.any?
          json.actions do |js|
            aspecs.each { |action_spec| add_child js, normalize_hash(type, action_spec) }
          end
        end
      end

      def expand_resource_custom_actions(resource, json, type, physical_attrs)
        return unless render_actions(physical_attrs) && collection_config.custom_actions?(type)

        href = @req.subcollection.present? ? normalize_url("#{@req.subcollection}/#{resource.id}") : json.attributes!["href"]
        json.actions do |js|
          resource_custom_action_names(resource).each do |action|
            add_child js, "name" => action, "method" => :post, "href" => href
          end
        end
      end

      def resource_custom_action_names(resource)
        return [] unless resource.respond_to?(:custom_action_buttons)
        Array(resource.custom_action_buttons).collect(&:name).collect(&:downcase)
      end

      def validate_attr_selection(resource)
        physical_attrs, virtual_attrs = [], []
        attrs = attribute_selection
        return [physical_attrs, virtual_attrs] if resource.kind_of?(Hash) || attrs == 'all'
        return [attrs, virtual_attrs] if (attrs - ID_ATTRS).empty?

        attrs.each do |attr|
          if attr_physical?(resource, attr) || attr == 'actions'
            physical_attrs.push(attr)
          elsif attr_virtual?(resource, attr) || @additional_attributes.try(:include?, attr)
            virtual_attrs.push(attr)
          end
        end

        attrs = attrs - physical_attrs - virtual_attrs
        raise BadRequestError, "Invalid attributes specified: #{attrs.join(',')}" unless attrs.empty?

        [(physical_attrs - ID_ATTRS).empty? ? [] : physical_attrs, virtual_attrs]
      end

      #
      # Let's expand a subcollection
      #
      def expand_subcollection(json, sc, sctype, subresources)
        if collection_config.show_as_collection?(sc)
          copts = {
            :counts           => Api::QueryCounts.new(subresources.length),
            :is_subcollection => true,
            :expand_resources => @req.expand?(sc)
          }
          json.set! sc.to_s, collection_to_jbuilder(sc.to_sym, sctype, subresources, copts)
        elsif subresources.kind_of?(Hash)
          json.set!(sc, normalize_hash(sctype, subresources))
        else
          sc_key_id = collection_config.resource_identifier(sctype)
          json.set! sc.to_s do |js|
            subresources.each do |scr|
              if @req.expand?(sc) || scr[sc_key_id].nil?
                add_child js, normalize_hash(sctype, scr)
              else
                js.child! { |jsc| jsc.href normalize_href(sctype, scr[sc_key_id]) }
              end
            end
          end
        end
      end

      def gen_action_spec_for_collections(collection, cspec, is_subcollection, href)
        if is_subcollection
          target = :subcollection_actions
          cspec_target = collection_config.typed_subcollection_actions(@req.collection, collection) || cspec[target]
        else
          target = :collection_actions
          cspec_target = cspec[target]
        end
        return [] unless cspec_target
        cspec_target.each.collect do |method, action_definitions|
          next unless render_actions_for_method(cspec[:verbs], method)
          typed_action_definitions = fetch_typed_subcollection_actions(method, is_subcollection) || action_definitions
          typed_action_definitions.each.collect do |action|
            if api_user_role_allows?(action[:identifier])
              {"name" => action[:name], "method" => method, "href" => (href ? href : collection)}
            end
          end
        end.flatten.compact
      end

      def gen_action_spec_for_resources(cspec, is_subcollection, href, resource)
        if is_subcollection
          target = :subresource_actions
          cspec_target = cspec[target] || collection_config.typed_subcollection_actions(@req.collection, @req.subcollection, :subresource)
        else
          target = :resource_actions
          cspec_target = cspec[target]
        end
        return [] unless cspec_target
        cspec_target.each.collect do |method, action_definitions|
          next unless render_actions_for_method(cspec[:verbs], method)
          typed_action_definitions = action_definitions || fetch_typed_subcollection_actions(method, is_subcollection)
          typed_action_definitions.each.collect do |action|
            next unless api_user_role_allows?(action[:identifier]) && action_validated?(resource, action)

            build_resource_actions(action, method, href, cspec[:verbs])
          end
        end.flatten.uniq.compact
      end

      def build_resource_actions(action, method, href, verbs)
        actions = [{"name" => action[:name], "method" => method, "href" => href}]
        if action[:name] == "edit"
          actions << { 'name' => 'edit', 'method' => :patch, 'href' => href } if verbs.include?(:patch)
          actions << { 'name' => 'edit', 'method' => :put, 'href' => href } if verbs.include?(:put)
        end
        actions
      end

      def render_actions_for_method(methods, method)
        method != :get && methods.include?(method)
      end

      def fetch_typed_subcollection_actions(method, is_subcollection)
        return unless is_subcollection
        collection_config.typed_subcollection_action(@req.collection, @req.subcollection, method)
      end

      def custom_api_user_role_allows_method?(_action_identifier)
        false
      end

      def api_user_role_allows?(action_identifier)
        return true unless action_identifier

        return custom_api_user_role_allows?(action_identifier) if custom_api_user_role_allows_method?(action_identifier)

        @role_allows_cache ||= {}
        Array(action_identifier).any? do |identifier|
          unless @role_allows_cache.key?(identifier)
            @role_allows_cache[identifier] = User.current_user.role_allows?(:identifier => identifier)
          end
          @role_allows_cache[identifier]
        end
      end

      def render_actions(physical_attrs)
        render_attr("actions") || physical_attrs.blank?
      end

      def action_validated?(resource, action_spec)
        if action_spec[:options] && action_spec[:options].include?(:validate_action)
          validate_method = "validate_#{action_spec[:name]}"
          return resource.respond_to?(validate_method) && resource.send(validate_method)
        end
        true
      end

      def render_options(resource, data = {})
        klass = collection_class(resource)
        render :json => OptionsSerializer.new(klass, data).serialize
      end

      def render_resource_options(id, action)
        type = @req.collection.to_sym
        resource = resource_search(id, type)
        raise BadRequestError, resource.unsupported_reason(action) unless resource.supports?(action)

        schema = resource.send("params_for_#{action}".to_sym)
        render_options(type, :form_schema => schema)
      end

      def render_create_resource_options(ems_id)
        type = @req.collection.to_sym
        base_klass = collection_class(type)

        ems = resource_search(ems_id, :providers)
        klass = ems.class_by_ems(base_klass.name)
        raise BadRequestError, "No #{type.to_s.titleize} support for - #{ems.name}" unless klass
        raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

        schema = klass.method(:params_for_create).arity == 0 ? klass.params_for_create : klass.params_for_create(ems)
        render_options(type, :form_schema => schema)
      end

      # This is a helper method used by both .determine_include_for_find and
      # .determine_extra_cols to collect and filter virtual_attributes for the
      # :include_for_find and :extra_cols options that are passed to Rbac. The
      # intent is to reduce a large amount of shared code between those two
      # shared methods by combining them into this one.
      #
      # The required block used by each of aforementioned methods is used to do
      # custom filtering that pertains to each of those methods.
      #
      def virtual_attributes_for(klass)
        return nil unless klass.respond_to?(:reflect_on_association)

        type    = @req.subject
        results = []

        validate_attr_selection(klass).last.each do |vattr|
          next if vattr == "href_slug"

          attr_name, attr_base = split_virtual_attribute(vattr)
          filtered_attr        = yield type, attr_name, attr_base

          results << filtered_attr if filtered_attr
        end

        results.empty? ? nil : results
      end

      def attr_base_uses_rbac?(attr_base)
        attr_base.split(".").any? do |relation|
          relation_class = relation.singularize.classify
          Rbac::Filterer::CLASSES_THAT_PARTICIPATE_IN_RBAC.include?(relation_class)
        end
      end

      def determine_include_for_find(klass)
        attrs = virtual_attributes_for(klass) do |type, attr_name, attr_base|
          if klass.virtual_includes(attr_name) && !klass.attribute_supported_by_sql?(attr_name) && attr_base.blank?
            attr_name
          else
            next if attr_base.blank?
            next if virtual_attribute_accessor(type, attr_name)
            next if attr_base_uses_rbac?(attr_base)

            attr_base
          end
        end

        # Handle nested relationships and convert to a hash
        if attrs
          attrs.each_with_object({}) do |key, include_for_find|
            if (virtual_includes = klass.virtual_includes(key))
              ActiveRecord::Base.merge_includes(include_for_find, virtual_includes)
            else
              nested = include_for_find
              key.split(".").each { |k| nested = nested[k] ||= {} }
            end
          end
        end
      end

      def determine_extra_cols(klass)
        virtual_attributes_for(klass) do |type, attr_name, attr_base|
          next if attr_base.present?
          next if virtual_attribute_accessor(type, attr_name)
          next unless klass.attribute_supported_by_sql?(attr_name)

          attr_name.to_sym
        end
      end

      # given a response to render, determine the proper return code
      # index pages have a response array of objects or hash that represents an object
      # show pages have resource as an object, or a hash representing an object
      # all of these pages just want to return ok
      #
      # the create and update pages are the ones we want to give a status
      # if there are multiple response entries, we just return ok
      # but if there is a single response, we'll use status to determine the resposne code
      #
      # So there are many ways we want to render and only a fraction of them will
      # use success to determine the return status - that is why so much short circuit logic
      #
      # @param [Object,Array[Object],Hash,Hash{String=>Array[Hash]}] resource
      # @return [Symbol] http status code
      def status_from_resource(resource)
        return :ok if @req.bulk? || !resource.kind_of?(Hash)
        return resource[:success] ? :ok : :bad_request if resource.key?(:success)

        results = resource["results"]
        if !results.kind_of?(Array) || !results.first.kind_of?(Hash) || !results.first.key?(:success) || results.first[:success]
          :ok
        else
          :bad_request
        end
      end

      # currently, this is only called if it has a value
      def integer_param(param_name)
        value = params[param_name].to_s
        raise(ArgumentError, "Non numeric #{param_name}") if value.match?(/[^0-9]/)
        value
      end
    end
  end
end
