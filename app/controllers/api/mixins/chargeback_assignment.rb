module Api
  module Mixins
    module ChargebackAssignment
      include Api::Mixins::Tags

      PARAMETERS_KEYS = %w[resource tag].freeze
      CHARGEBACK_RATE_KEY = 'chargeback'.freeze
      ALLOWED_CLASSES_FOR = {
        'resource' => {'Compute' => %w[Tenant ExtManagementSystem EmsCluster MiqEnterprise], 'Storage' => %w[Tenant MiqEnterprise Storage]},
        'label'    => {'Compute' => %w[CustomAttribute], 'Storage' => %w[]}
      }.freeze

      ALLOWED_TAG_PREFIXES = {
        'Compute' => %w[vm container_image],
        'Storage' => %w[storage]
      }.freeze

      TYPES_OF_ASSIGNMENTS = %w[object label tag].freeze

      def normalize_attr(attr, value)
        value = assigments_to_result(value, []) if attr == "assigned_to"

        super(attr, value)
      end

      def label_record?(parameter_record)
        return false unless parameter_record['resource']

        resource_href = parameter_record['resource']['href']
        href = Api::Href.new(resource_href)

        klass = collection_class(href.subject)
        klass == CustomAttribute
      rescue => err
        raise BadRequestError, "Cannot parse href '#{href.subject}': #{err}"
      end

      def determine_type(parameter_record)
        return :label if label_record?(parameter_record)

        type = PARAMETERS_KEYS.detect { |parameter_key| parameter_record.keys.sort == [CHARGEBACK_RATE_KEY, parameter_key].sort }

        raise BadRequestError, "Cannot determine #{type} type of target resource." unless type

        type
      end

      def target_classification_by(category_name, entry_name)
        target_category = Classification.lookup_by_name(category_name)
        if target_category
          target_classification = target_category.find_entry_by_name(entry_name)
          raise BadRequestError, "Cannot find tag '#{entry_name}' ." unless target_classification

          target_classification
        else
          raise BadRequestError, "Cannot find '#{category_name}' category of tag '#{entry_name}'."
        end
      end

      def tag_record_validation(record, rate_type)
        return if record['assignment_prefix'].blank? && rate_type == "Storage"

        raise BadRequestError, "'assignment_prefix' is missing for target record." unless record['assignment_prefix']
        raise BadRequestError, "'#{record['assignment_prefix']}' assignment_prefix is not valid for target record." unless ALLOWED_TAG_PREFIXES[rate_type].include?(record['assignment_prefix'])
      end

      def target_from(target_href, assignment_type, rate_type)
        raise BadRequestError, "'href' attribute expected for target resource" unless target_href

        href = Api::Href.new(target_href)
        klass = collection_class(href.subject)

        target = klass.find(href.subject_id)

        filter_resource(target, href.subject, klass)

        validate_target_class(target, assignment_type, rate_type)

        target
      rescue => err
        raise BadRequestError, "Cannot determine target resource for collection #{href.subject} and #{href.subject_id}: #{err.message}"
      end

      def target_add_label_defaults(target)
        [target, 'container_image']
      end

      def tag_assigment(record, rate_type)
        tag_record_validation(record, rate_type)
        target_tag = parse_tag(record)
        raise BadRequestError, "Unable to parse tag: #{record}" if target_tag[:category].nil? || target_tag[:name].nil?

        target_classification_by(target_tag[:category], target_tag[:name])
      end

      def validate_target_class(target, assignment_type, rate_type)
        base_class_name = target.class.base_class.name
        raise BadRequestError, "Class '#{base_class_name}' of target resource is no valid." unless ALLOWED_CLASSES_FOR[assignment_type.to_s][rate_type].include?(base_class_name)
      end

      def chargeback_rate(parameter_record)
        rate_id = parse_id(parameter_record[CHARGEBACK_RATE_KEY], :chargebacks)
        @chargeback_rate ||= {}
        @chargeback_rate[rate_id] ||= ChargebackRate.find(rate_id)
      end

      def tag_target_assignment(record, _assignment_type, rate_type)
        target = tag_assigment(record, rate_type)
        [target, rate_type == "Storage" ? 'storage' : record['assignment_prefix']]
      end

      def label_target_assignment(record, assignment_type, rate_type)
        target = target_from(record['href'], assignment_type, rate_type)
        target_add_label_defaults(target)
      end

      def resource_target_assignment(record, assignment_type, rate_type)
        target_from(record['href'], assignment_type, rate_type)
      end

      def target(parameter_record, assignment_type, rate_type)
        target_assignment_method = "#{assignment_type}_target_assignment"
        send(target_assignment_method, parameter_record[assignment_type.to_s], assignment_type, rate_type)
      end

      def convert_assignment_key_from(parameter_key)
        parameter_key == 'resource' ? :object : parameter_key.to_sym
      end

      def rate_assignment(parameter_record, assignment_type, rate_type)
        parameter_record['label'] = parameter_record.delete('resource') if assignment_type == :label

        rate = chargeback_rate(parameter_record)

        {:cb_rate => rate, convert_assignment_key_from(assignment_type) => target(parameter_record, assignment_type, rate_type)}
      end

      def determine_assignment_type(parameter_records)
        assignment_types = parameter_records.map { |parameter_record| determine_type(parameter_record) }.uniq

        raise BadRequestError, "More than one type of target resources are not expected." unless assignment_types.count == 1

        assignment_types.first
      end

      def validate_target(record, assignment_type, second_value)
        if record[assignment_type].kind_of?(Array) # labels and tags
          klass = klass_for(assignment_type)
          label_condition = assignment_type == :label ? (record[:label][0].resource_type == "ContainerImage") : true

          label_condition && record[assignment_type][0].kind_of?(klass) && second_value && record[assignment_type][1] == second_value
        else
          klass = klass_for(assignment_type, second_value)
          record[assignment_type].kind_of?(klass) && assignment_type == :object
        end
      end

      def klass_for(assignment_type, object = nil)
        case assignment_type
        when :object
          object.class.base_class
        when :label
          CustomAttribute
        when :tag
          Classification
        end
      end

      def validate_targets_by_type(assignments, assignment_type)
        second_value = assignments.first[:object] || assignments.first[assignment_type][1]
        assignments.all? { |x| validate_target(x, assignment_type, second_value) }
      end

      def validate_uniqueness(assignments, assignment_type)
        assignments.map { |x| x[assignment_type].try(:id) || x[assignment_type][0].id }.uniq.count == assignments.count
      end

      def validate_targets(assignments, parameter_key)
        assignment_type = convert_assignment_key_from(parameter_key)

        validate_uniqueness(assignments, assignment_type) && validate_targets_by_type(assignments, assignment_type)
      end

      KLASS_TO_COLLECTION = {'ExtManagementSystem' => 'providers',
                             'Tenant'              => 'tenants',
                             'EmsCluster'          => 'clusters',
                             'MiqEnterprise'       => 'enterprises',
                             'Storage'             => 'data_stores'}.freeze

      def add_default_attributes_to_result(resource, collection)
        columns = collection_config[collection]&.identifying_attrs&.split(',') || %w[name description]
        columns.each do |column|
          return {column => resource.try(column)} if resource.try(column)
        end

        {}
      end

      def result_assignment_href(record, key)
        additional_attributes = {}
        resource_id = nil
        resource_collection = if key == :tag
                                tag = record[key][0]&.tag
                                prefix = record[key][1]
                                resource_id = tag.id
                                additional_attributes = {'name' => tag.classification.name, 'description' => tag.classification.description, 'category' => tag.category.name, :assignment_prefix => prefix}
                                :tags
                              elsif key == :object
                                key = :resource
                                resource_id = record[:object].id
                                collection = KLASS_TO_COLLECTION[record[:object].class.base_class.name]
                                additional_attributes = add_default_attributes_to_result(record[:object], collection)
                                collection
                              elsif key == :label
                                key = :resource
                                resource_id = record[:label][0].id
                                collection = :custom_attributes
                                additional_attributes = add_default_attributes_to_result(record[:label][0], collection)
                                "container_images/#{record[:label][0].resource_id}/custom_attributes"
                              end

        {key => {:href => normalize_href(resource_collection, resource_id)}.merge(additional_attributes)}
      end

      def result_rate(rate)
        {CHARGEBACK_RATE_KEY => {:href => normalize_href(:chargebacks, rate.id)}.merge(add_default_attributes_to_result(rate, :chargebacks))}
      end

      def result_assignment(record, key, with_rate)
        result = result_assignment_href(record, key)
        with_rate ? result_rate(record[:cb_rate]).merge(result) : result
      end

      def assigments_to_result(compute_assignments, assignment_keys = [:cb_rate])
        return [] if compute_assignments.empty?

        key = (compute_assignments.first.keys - assignment_keys).first

        compute_assignments.map { |x| result_assignment(x, key, assignment_keys == [:cb_rate]) }
      end

      def fetch_rates_from_params(params_assignments)
        rates_ids = params_assignments.map do |x|
          raise BadRequestError, "Key 'chargeback' is missing any of target resources." unless x[CHARGEBACK_RATE_KEY]

          parse_id(x[CHARGEBACK_RATE_KEY], :chargebacks)
        end
        ChargebackRate.where(:id => rates_ids).pluck(:id, :rate_type)
      end

      def parse_params(parameter_records, rate_type)
        assignment_type = determine_assignment_type(parameter_records)

        parameter_records = parameter_records.map { |parameter_record| rate_assignment(parameter_record, assignment_type, rate_type) }

        raise BadRequestError, "Input resources are not valid for #{assignment_type} rates." unless validate_targets(parameter_records, assignment_type)

        parameter_records
      end

      def group_assignments_from(params_assignments)
        grouped_rates_by_rate_type = {}
        fetch_rates_from_params(params_assignments).each do |id, rate_type|
          grouped_rates_by_rate_type[id] = rate_type
        end

        params_assignments.group_by { |x| grouped_rates_by_rate_type[parse_id(x[CHARGEBACK_RATE_KEY], :chargebacks)] }
      end

      def parse_resource_assignments(params_assignments, rate)
        raise BadRequestError, "Parameter 'assignments' is not passed." unless params_assignments
        raise BadRequestError, "Parameter 'assignments' is empty." if params_assignments.empty?

        assignments = params_assignments.map do |assignment|
          assignment[CHARGEBACK_RATE_KEY] = {'id' => rate.id}
          assignment
        end

        parse_params(assignments, rate.rate_type)
      end

      def parse_collection_assignments(params_assignments)
        raise BadRequestError, "Parameter 'assignments' is not passed." unless params_assignments
        raise BadRequestError, "Parameter 'assignments' is empty." if params_assignments.empty?

        assignments = group_assignments_from(params_assignments)

        parsed_assignments = {}
        ChargebackRate::VALID_CB_RATE_TYPES.each do |rate_type|
          parsed_assignments[rate_type] = parse_params(assignments[rate_type], rate_type) if assignments[rate_type]
        end

        parsed_assignments
      end

      def assign_resource(_type, rate_id, data)
        rate = resource_search(rate_id, :chargebacks, ChargebackRate)

        parsed_assignments = parse_resource_assignments(data['assignments'], rate)

        assignments = ChargebackRate.set_assignments(rate.rate_type, parsed_assignments)
        action_result(true, "Rates assigned successfully", :result => assigments_to_result(assignments))
      rescue => err
        action_result(false, err.message)
      end

      def assign_collection(_type, data = nil)
        parsed_assignments = parse_collection_assignments(data['assignments'])

        result = []

        ChargebackRate::VALID_CB_RATE_TYPES.each do |rate_type|
          if parsed_assignments[rate_type]
            assignments = ChargebackRate.set_assignments(rate_type, parsed_assignments[rate_type])
            result |= assigments_to_result(assignments)
          end
        end

        action_result(true, "Rates assigned successfully", :result => result.flatten)
      rescue => err
        action_result(false, err.to_s)
      end

      def unassign_resource(type, rate_id, data)
        klass = collection_class(type)
        rate = resource_search(rate_id, :type, klass)
        parsed_assignments = parse_resource_assignments(data['assignments'], rate)

        assignments = ChargebackRate.unassign_rate_assignments(rate.rate_type, parsed_assignments)
        action_result(true, "Rates unassigned successfully", :result => assigments_to_result(assignments))
      rescue => err
        action_result(false, err.to_s)
      end

      def unassign_collection(_type, data = nil)
        parsed_assignments = parse_collection_assignments(data['assignments'])

        result = []

        ChargebackRate::VALID_CB_RATE_TYPES.each do |rate_type|
          if parsed_assignments[rate_type]
            assignments = ChargebackRate.unassign_rate_assignments(rate_type, parsed_assignments[rate_type])
            result |= assigments_to_result(assignments)
          end
        end

        action_result(true, "Rates unassigned successfully", :result => result)
      rescue => err
        action_result(false, err.to_s)
      end
    end
  end
end
