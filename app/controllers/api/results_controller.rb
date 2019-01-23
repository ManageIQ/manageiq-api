module Api
  class ResultsController < BaseController
    before_action :set_additional_attributes, :only => [:index, :show]

    def results_search_conditions
      MiqReportResult.for_user(User.current_user).where_clause.ast
    end

    def apply_limit_and_offset(results, options)
      results.slice(options['offset'].to_i, options['limit'].to_i) || []
    end

    def sort_order
      params['sort_order'] == 'desc' ? :descending : :ascending
    end

    def sort_by(report_result)
      sort_by(report_result).split(",").collect do |attr|
        if report(report_result).col_order&.include?(attr)
          attr
        else
          raise BadRequestError, "#{attr} is not a valid attribute for #{report_result.name}"
        end
      end.compact
    end

    def param_result_set?
      params.key?(:hash_attribute) && params[:hash_attribute] == "result_set"
    end

    def format_result_set(miq_report, result_set)
      tz = miq_report.get_time_zone(Time.zone)

      col_format_hash = miq_report.col_order.zip(miq_report.col_formats).to_h

      result_set.map! do |row|
        row.map do |key, _|
          [key, miq_report.format_column(key, row, tz, col_format_hash[key])]
        end.to_h
      end
    end

    def report(report_result)
      @report ||= report_result.report || report_result.miq_report
    end

    def sort_by(report_result)
      params['sort_by'] || report(report_result)&.sortby || report(report_result)&.col_order
    end

    def result_set
      ensure_pagination

      report_result = MiqReportResult.for_user(User.current_user).find(@req.collection_id)
      result_set = report_result.result_set

      if result_set.present? && report(report_result)
        result_set = result_set.stable_sort_by(sort_by(report_result), sort_order)
        result_set = apply_limit_and_offset(result_set, params)
        result_set.map! { |x| x.slice(*report(report_result).col_order) }

        result_set = format_result_set(report(report_result), result_set)
      end

      hash = {:result_set => result_set,
              :count      => report_result.result_set.count,
              :subcount   => result_set.count,
              :pages      => (report_result.result_set.count / params['limit'].to_f).ceil}

      report_result.attributes.merge(hash)
    end

    def show
      param_result_set? ? render_resource(:results, result_set) : super
    end

    def find_results(id)
      MiqReportResult.for_user(User.current_user).find(id)
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(result_set)
    end
  end
end
