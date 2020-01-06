module Api
  class ExpressionsController < BaseController
    AUTOCOMPLETE_ACTIONS = %w[registry_value registry_data registry_key registry_operator tag_value tag_field exp_type entity field category operator tag_operator expression_operator value check_operator].freeze
    REQUIRED_PARAMETERS_KEYS = %i[model autocomplete_actions].freeze

    def index
      REQUIRED_PARAMETERS_KEYS.each do |key|
        raise "Required parameter #{key} is missing" unless params[key]
      end

      autocomplete_actions = Array(params[:autocomplete_actions])
      if (autocomplete_actions & AUTOCOMPLETE_ACTIONS).empty?
        raise "Any of autocomplete actions: #{autocomplete_actions.join(", ")} is not allowed."
      end

      response = {}
      options = {:secondary_filter => params[:secondary_filter], :model => params[:model], :only_tag => params[:only_tag], :written_input => params[:written_input]}
      autocomplete_actions.each_with_object(response) do |action_name, _|
        autocomplete_action_method = "autocomplete_action_#{action_name}"
        response[action_name] = send(autocomplete_action_method, options) if respond_to?(autocomplete_action_method)
      end

      render :json => response
    end

    def autocomplete_action_exp_type(options)
      if options[:secondary_filter]
        ExpAtomHelper.expression_types_for_secondary_filter(options[:columns_order], options[:columns])
      else
        ExpAtomHelper.expression_types_for_primary_filter(options[:model], options[:only_tag])
      end.map(&:first)
    end

    def find_reflection_by(human_name, model)
      parent = {}
      parent[:assoc_path] = model
      parent[:root] = model

      MiqExpression.expression_reflections_for(model, parent).detect do |reflection_options|
        human_name.strip == reflection_options[:human_name]
      end
    end

    def relations_in_human_form_for(model, root_model)
      parent = {}
      parent[:assoc_path] = root_model
      parent[:root] = root_model
      MiqExpression.expression_reflections_for(model, parent).map { |x| x[:human_name] } || []
    end

    def autocomplete_action_entity(options)
      written_input = options[:written_input] || []
      model = options[:model]
      root_model = model

      raise "Unable to find #{model}" unless model.safe_constantize

      case written_input.count
      when 0
        [MiqExpression.value2human(model).strip]
      when 1
        written_input.last == MiqExpression.value2human(model).strip ? relations_in_human_form_for(model, root_model) : []
      when 2
        relation = model_info_from(written_input, model, 1)
        association_model = relation&.dig(:association_klass)

        if association_model && !MiqExpression.parse_field_or_tag("#{model}.#{relation[:association]}")&.plural?
          relations_in_human_form_for(association_model, root_model)
        else
          []
        end
      else
        []
      end
    end

    def model_info_from(written_input, model, offset = 2)
      if written_input.count > offset
        written_input[1..-offset].map do |human_entity|
          relation = find_reflection_by(human_entity, model)
          model = relation&.dig(:association_klass)
          relation
        end.last
      else
        {:association_klass => model}
      end
    end

    def autocomplete_action_field(options)
      written_input = options[:written_input] || []

      model = options[:model]

      raise "Unable to find #{model}" unless model.safe_constantize

      model = model_info_from(written_input, model, 1)[:association_klass]

      columns = model.safe_constantize.attribute_names.map do |x|
        MiqExpression.value2human("#{model}-#{x}").split(":").last.strip
      end
      model ? columns : []
    end

    def autocomplete_action_value(options)
      model = options[:model]

      raise "Unable to find #{model}" unless model.safe_constantize

      _operator = options[:written_input].pop
      written_input = options[:written_input]

      return [] if written_input.count < 2

      model = model_info_from(written_input, options[:model])[:association_klass]

      column_from_input = written_input.last
      column = column_by_human_name(column_from_input, model)

      MiqExpression::Field.parse("#{model}-#{column}").column_values
    end

    def autocomplete_action_operator(options)
      model = options[:model]

      raise "Unable to find #{model}" unless model.safe_constantize

      written_input = options[:written_input]

      return [] if written_input.count < 2

      model = model_info_from(written_input, options[:model])[:association_klass]

      column_from_input = written_input.last
      column = column_by_human_name(column_from_input, model)

      MiqExpression.get_col_operators("#{model}-#{column}")
    end

    def column_by_human_name(human_value, model)
      model.safe_constantize.attribute_names.detect do |x|
        human_value.strip == MiqExpression.value2human("#{model}-#{x}").split(":").last.strip
      end
    end

    def autocomplete_action_tag_field(options)
      model = options[:model]

      setting = {:typ => 'tag', :include_table => true, :include_model => false, :include_my_tags => false}

      MiqExpression::TAG_CLASSES.invert.each_with_object([]) do |(tag_association, tag_klass), return_array|
        next if tag_klass.constantize.base_class == model.constantize.base_class

        return_array.push(MiqExpression.value2human("#{model}.#{tag_association}", setting).strip)
      end
    end

    def autocomplete_action_category(options)
      model = options[:model]

      if MiqExpression::TAG_CLASSES.include?(model)
        ret = []
        @classifications ||= MiqExpression.categories
        @classifications.each do |_, classification|
          ret << classification.description
        end

        ret.sort! { |a, b| a.to_s <=> b.to_s }
      else
        []
      end
    end

    def autocomplete_action_tag_value(options)
      model = options[:model]
      humanize_tag_field = options[:written_input]&.last&.strip

      if MiqExpression::TAG_CLASSES.include?(model) && humanize_tag_field
        @classifications ||= MiqExpression.categories
        target_classification = @classifications.detect do |_, classification|
          classification.description == humanize_tag_field
        end
        target_classification ? target_classification.second.entries.map(&:description) : []
      else
        []
      end
    end

    def autocomplete_action_tag_operator(_options)
      ["CONTAINS"]
    end

    def autocomplete_action_expression_operator(_options)
      %w(AND OR)
    end

    def autocomplete_action_check_operator(_options)
      ["CHECK ALL", "CHECK ANY", "CHECK COUNT"]
    end

    def autocomplete_action_registry_key(_options)
      RegistryItem.all.map { |x| x.name.split(" : ").first + " :" }.uniq
    end

    def autocomplete_action_registry_operator(options)
      options[:written_input].count == 1 ? %w[KEY\ EXISTS] : MiqExpression::REGKEY_OPERATORS - %w[KEY\ EXISTS] + MiqExpression::STRING_OPERATORS
    end

    def autocomplete_action_registry_value(options)
      written_registry_key = options[:written_input].last.gsub('\\\\', '\\').strip

      RegistryItem.where("name LIKE ? ESCAPE ''", written_registry_key + "%").map { |x| x.name.split(" : ").second }.uniq
    end

    def autocomplete_action_registry_data(options)
      written_registry_key, written_registry_value = options[:written_input]
      written_registry_key.gsub!('\\\\', '\\').strip
      written_registry_value.strip!

      RegistryItem.where(:name => "#{written_registry_key} #{written_registry_value}").pluck(:data).uniq
    end
  end
end