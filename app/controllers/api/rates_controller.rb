module Api
  class RatesController < BaseController
    def create_resource(_type, _id, data = {})
      parse_relation_from(data, "detail_currency", :currency, :currencies)
      parse_relation_from(data, "chargeable_field", :chargeable_field, :chargeable_fields)
      parse_relation_from(data, "chargeback_rate", :chargeback, :chargebacks)

      parse_tiers(data)

      super
    end

    def edit_resource(_type, _resource_id, data)
      parse_relation_from(data, "detail_currency", :currency, :currencies)
      parse_relation_from(data, "chargeable_field", :chargeable_field, :chargeable_fields)
      parse_tiers(data) if data['chargeback_tiers']
      parse_relation_from(data, "chargeback_rate", :chargeback, :chargebacks) if data['chargeback_rate']

      super
    end

    def parse_relation_from(data, parameter_key, type, collection)
      resource_relation = data[parameter_key]

      if resource_relation.present?
        resource_id = parse_id(resource_relation, collection)
        raise BadRequestError, "Missing #{type} identifier href or id" unless resource_id

        resource = resource_search(resource_id, collection)
        data[parameter_key] = resource if resource
      end
    end

    def parse_tiers(data)
      raise BadRequestError, "chargeback_tiers needs to be specified" if data['chargeback_tiers'].nil?

      tiers = data['chargeback_tiers'].map do |tier_parameters|
        if (tier_parameters['start'] && tier_parameters['finish']).nil?
          raise BadRequestError, "Attributes start and finish have to be specified for chargeback tier."
        end

        tier_parameters['finish'] = normalize_input_value(tier_parameters['finish'])

        tier = ChargebackTier.new(tier_parameters)
        raise BadRequestError, "#{tier.errors.full_messages.join(', ')} (Tier is not valid)" unless tier.valid?

        tier
      end

      rate_detail = ChargebackRateDetail.new(:chargeback_tiers => tiers)

      if rate_detail.contiguous_tiers?
        data['chargeback_tiers'] = tiers
      else
        raise BadRequestError, "#{rate_detail.errors.full_messages.join(', ')} (Tiers are not valid)"
      end
    end
  end
end
