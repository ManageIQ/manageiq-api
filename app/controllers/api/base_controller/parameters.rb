module Api
  class BaseController
    module Parameters
      module ResultsController
        def sort_order
          params['sort_order'] == 'desc' ? :descending : :ascending
        end

        def param_result_set?
          params.key?(:hash_attribute) && params[:hash_attribute] == "result_set"
        end

        def report_options
          params.merge(:sort_order => sort_order)
        end
      end

      def hash_fetch(hash, element, default = {})
        hash[element] || default
      end

      #
      # Returns an MiqExpression based on the filter attributes specified.
      #
      def filter_param(klass)
        return nil if params['filter'].blank?
        Filter.parse(params["filter"], klass)
      end

      def by_tag_param
        params['by_tag']
      end

      def search_options
        params['search_options'].to_s.split(",")
      end

      def search_option?(what)
        search_options.map(&:downcase).include?(what.to_s)
      end

      def format_attributes
        params['format_attributes'].to_s.split(",").map { |af| af.split("=").map(&:strip) }
      end

      def attribute_format(attr)
        format_attributes.detect { |af| af.first == attr }.try(:second)
      end

      def attribute_selection
        if @req.attributes.empty? && @additional_attributes
          Array(@additional_attributes) | ID_ATTRS
        elsif !@req.attributes.empty?
          @req.attributes | ID_ATTRS
        else
          "all"
        end
      end

      def attribute_selection_for(collection)
        Array(attribute_selection).collect do |attr|
          /\A#{collection}\.(?<name>.*)\z/.match(attr) { |m| m[:name] }
        end.compact
      end

      def render_attr(attr)
        as = attribute_selection
        as == "all" || as.include?(attr)
      end

      #
      # Returns the ActiveRecord's option for :order
      #
      # i.e. ['attr1 [asc|desc]', 'attr2 [asc|desc]', ...]
      #
      def sort_params(klass)
        return [] if params['sort_by'].blank?

        orders = String(params['sort_order']).split(",")
        options = String(params['sort_options']).split(",")
        params['sort_by'].split(",").zip(orders).collect do |attr, order|
          if klass.virtual_attribute?(attr) && !klass.attribute_supported_by_sql?(attr)
            raise BadRequestError, "#{klass.name} cannot be sorted by #{attr}"
          elsif klass.attribute_supported_by_sql?(attr)
            sort_directive(klass, attr, order, options)
          else
            raise BadRequestError, "#{attr} is not a valid attribute for #{klass.name}"
          end
        end.compact
      end

      def sort_directive(klass, attr, order, options)
        arel = klass.arel_attribute(attr)
        if order
          arel = arel.lower if options.map(&:downcase).include?("ignore_case")
          arel = arel.desc if order.downcase == "desc"
          arel = arel.asc if order.downcase == "asc"
        else
          arel = arel.asc
        end
        arel
      end

      def determine_include_for_find(klass)
        return nil unless klass.respond_to?(:reflect_on_association)

        relations = @req.derived_include_for_find.select do |relation|
                      klass.reflect_on_association(relation)
                    end

        relations.empty? ? nil : relations
      end
    end
  end
end
