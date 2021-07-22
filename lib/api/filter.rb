module Api
  class Filter
    VALID_OPTIONS = [:and_priority, :or_priority]
    OPERATORS     = {
      "!="  => {:default => "!=", :regex => "REGULAR EXPRESSION DOES NOT MATCH", :null => "IS NOT NULL"},
      "<="  => {:default => "<="},
      ">="  => {:default => ">="},
      "<"   => {:default => "<", :datetime => "BEFORE"},
      ">"   => {:default => ">", :datetime => "AFTER"},
      "="   => {:default => "=", :datetime => "IS", :regex => "REGULAR EXPRESSION MATCHES", :string_set => "includes all", :null => "IS NULL"},

      # string-only matching, use quotes
      "=="  => {:default => "="},
      "!==" => {:default => "!="},

      # regex-only matching without mangling, use slashes and optionally /i
      "=~"  => {:default => "REGULAR EXPRESSION MATCHES"},
      "!~"  => {:default => "REGULAR EXPRESSION DOES NOT MATCH"},
    }.freeze

    attr_reader :filters, :model, :options, :and_expressions, :or_expressions

    def self.parse(filters, model, options=nil)
      new(filters, model, options).parse
    end

    def initialize(filters, model, options=nil)
      @filters         = filters
      @model           = model
      @options         = parse_options(options)
      @and_expressions = []
      @or_expressions  = []
    end

    def parse
      filters.select(&:present?).each do |filter|
        parsed_filter = parse_filter(filter)
        *associations, attr = parsed_filter[:attr].split(".")
        if associations.size > 1
          raise BadRequestError, "Filtering of attributes with more than one association away is not supported"
        end
        unless virtual_or_physical_attribute?(target_class(model, associations), attr)
          raise BadRequestError, "attribute #{attr} does not exist"
        end

        associations.map! { |assoc| ".#{assoc}" }

        field = "#{model.name}#{associations.join}-#{attr}"
        expr  = {parsed_filter[:operator] => {"field" => field, "value" => parsed_filter[:value]}}

        if parsed_filter[:logical_or]
          or_expressions << and_expressions.pop if options[:and_priority]
          or_expressions << expr
        else
          and_expressions << expr
        end
      end

      MiqExpression.new(composite_expression).tap do |expression|
        raise BadRequestError, "Must filter on valid attributes for resource" unless expression.valid?
      end
    end

    private

    def parse_options(options)
      return {} if options.nil?

      opts = options.to_s.split(",").map(&:to_sym) & VALID_OPTIONS

      opts.map {|opt| [opt, true]}.to_h
    end

    def parse_filter(filter)
      logical_or = filter.gsub!(/^or /i, '').present?

      operator = nil
      operators_from_longest_to_shortest = OPERATORS.keys.sort_by(&:size).reverse
      filter.size.times do |i|
        operator = operators_from_longest_to_shortest.detect do |o|
          o == filter[(i..(i + o.size - 1))]
        end
        break if operator
      end

      if operator.blank?
        raise BadRequestError, "Unknown operator specified in filter #{filter}"
      end

      methods = OPERATORS[operator]
      filter_attr, _, filter_value = filter.partition(operator)
      filter_attr.strip!
      filter_value.strip!

      is_regex = filter_value =~ /%|\*/ && methods[:regex]
      str_method = is_regex ? methods[:regex] : methods[:default]

      filter_value, method = case filter_value
                             when /^'(.*)'$/, /^"(.*)"$/
                               unquoted_filter_value = $1
                               if column_type(model, filter_attr) == :string_set && methods[:string_set]
                                 [unquoted_filter_value, methods[:string_set]]
                               else
                                 [unquoted_filter_value, str_method]
                               end
                             when /^(NULL|nil)$/i
                               [nil, methods[:null] || methods[:default]]
                             else
                               if column_type(model, filter_attr) == :datetime
                                 unless methods[:datetime]
                                   raise BadRequestError, "Unsupported operator for datetime: #{operator}"
                                 end
                                 unless Time.zone.parse(filter_value)
                                   raise BadRequestError, "Bad format for datetime: #{filter_value}"
                                 end

                                 [filter_value, methods[:datetime]]
                               else
                                 [filter_value, methods[:default]]
                               end
                             end

      if is_regex
        filter_value = "/\\A#{Regexp.escape(filter_value)}\\z/"
        filter_value.gsub!(/%|\\\*/, ".*")
      end

      {:logical_or => logical_or, :operator => method, :attr => filter_attr, :value => filter_value}
    end

    def composite_expression
      if options[:and_priority]
        or_part = or_expressions.one? ? or_expressions.first : {"OR" => or_expressions}
        and_expressions.empty? ? or_part : {"AND" => [or_part, *and_expressions]}
      else
        and_part = and_expressions.one? ? and_expressions.first : {"AND" => and_expressions}
        or_expressions.empty? ? and_part : {"OR" => [and_part, *or_expressions]}
      end
    end

    def target_class(klass, reflections)
      if reflections.empty?
        klass
      else
        target_class(klass.reflections_with_virtual[reflections.first.to_sym].klass, reflections[1..-1])
      end
    end

    def virtual_or_physical_attribute?(klass, attribute)
      klass.attribute_method?(attribute) || klass.virtual_attribute?(attribute)
    end
  end
end
