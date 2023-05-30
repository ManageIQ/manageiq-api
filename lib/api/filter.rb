module Api
  class Filter
    OPERATORS = {
      "!="  => {:default => "!=", :regex => "REGULAR EXPRESSION DOES NOT MATCH", :null => "IS NOT NULL"},
      "<="  => {:default => "<="},
      ">="  => {:default => ">="},
      "<"   => {:default => "<", :datetime => "BEFORE"},
      ">"   => {:default => ">", :datetime => "AFTER"},
      "="   => {:default => "=", :datetime => "IS", :regex => "REGULAR EXPRESSION MATCHES", :string_set => "includes all", :array => "=", :null => "IS NULL"},

      # string-only matching, use quotes
      "=="  => {:default => "="},
      "!==" => {:default => "!="},

      # regex-only matching without mangling, use slashes and optionally /i
      "=~"  => {:default => "REGULAR EXPRESSION MATCHES"},
      "!~"  => {:default => "REGULAR EXPRESSION DOES NOT MATCH"},
    }.freeze

    attr_reader :filters, :model, :and_expressions, :or_expressions

    def self.parse(filters, model)
      new(filters, model).parse
    end

    def initialize(filters, model)
      @filters         = filters
      @model           = model
      @and_expressions = []
      @or_expressions  = []
    end

    def parse
      filters.select(&:present?).each do |filter|
        parsed_filter = parse_filter(filter)
        field = parsed_filter[:field]
        if field.associations.size > 1
          raise BadRequestError, "Filtering of attributes with more than one association away is not supported"
        end
        unless field.valid?
          raise BadRequestError, "attribute #{field} does not exist"
        end

        op    = parsed_filter[:operator]
        expr  = if parsed_filter[:value].kind_of?(Array)
                  {"OR" => parsed_filter[:value].map { |val| single_expression(field, op, val) }}
                else
                  single_expression(field, op, parsed_filter[:value])
                end

        if parsed_filter[:logical_or]
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

    def parse_filter(filter)
      logical_or = filter.gsub!(/^or /i, '').present?
      filter_field, operator, filter_value = split_filter_string(filter)
      methods = OPERATORS[operator]

      is_regex = filter_value =~ /%|\*/ && methods[:regex]
      str_method = is_regex ? methods[:regex] : methods[:default]

      filter_value, method = case filter_value
                             when /^\[(.*)\]$/
                               unless methods[:array]
                                 raise BadRequestError, "Unsupported operator for arrays: #{operator}"
                               end

                               array_value = $1.split(",")
                               [array_value, methods[:array]]
                             when /^'(.*)'$/, /^"(.*)"$/
                               unquoted_filter_value = $1
                               if filter_field.column_type == :string_set && methods[:string_set]
                                 [unquoted_filter_value, methods[:string_set]]
                               else
                                 [unquoted_filter_value, str_method]
                               end
                             when /^(NULL|nil)$/i
                               [nil, methods[:null] || methods[:default]]
                             else
                               if filter_field.datetime?
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

      {:logical_or => logical_or, :operator => method, :field => filter_field, :value => filter_value}
    end

    def composite_expression
      and_part = and_expressions.one? ? and_expressions.first : {"AND" => and_expressions}
      or_expressions.empty? ? and_part : {"OR" => [and_part, *or_expressions]}
    end

    def single_expression(field, operator, value)
      {operator => {"field" => field.to_s, "value" => value}}
    end

    def split_filter_string(filter)
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

      filter_attr, _op, filter_value = filter.partition(operator)
      filter_value.strip!
      filter_attr.strip!
      *associations, attr_name = filter_attr.split(".")
      [MiqExpression::Field.new(model, associations, attr_name), operator, filter_value]
    end
  end
end
