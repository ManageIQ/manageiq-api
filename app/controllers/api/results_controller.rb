module Api
  class ResultsController < BaseController
    before_action :set_additional_attributes, :only => [:index, :show]

    def results_search_conditions
      MiqReportResult.for_user(User.current_user).where_clause.ast
    end

    def find_results(id)
      MiqReportResult.for_user(User.current_user).find(id)
    end

    private

    def fetch_direct_virtual_attribute(type, resource, attr)
      return unless attr_accessible?(resource, attr)
      virtattr_accessor = virtual_attribute_accessor(type, attr)
      value = virtattr_accessor ? send(virtattr_accessor, resource) : virtual_attribute_search(resource, attr)
      value = add_custom_action_hrefs(value) if attr == "custom_actions"
      if attr == "result_set"
        offset = request.params[:offset] ? request.params[:offset].to_i : 0
        limit = request.params[:limit] ? request.params[:limit].to_i : 0
        value = value.sort_by{|hash| hash[:id] }[offset...offset+limit] if limit > 0
      end
      result = {attr => normalize_attr(attr, value)}
      # set nil vtype above to "#{type}/#{resource.id}/#{attr}" to support id normalization
      [value, result]
    end

    def set_additional_attributes
      @additional_attributes = %w(result_set)
    end
  end
end
