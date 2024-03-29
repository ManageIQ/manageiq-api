module Api
  class BaseController
    module Results
      private

      def single_resource?
        @req.method == :delete || !@req.json_body.key?('resources')
      end

      def action_result(success, message = nil, options = {})
        res = {:success => success}
        res[:message] = message if message.present?
        res[:result]  = options[:result] unless options[:result].nil?
        add_task_to_result(res, options[:task_id]) if options[:task_id].present?
        add_task_results_href_to_result(res, options[:task_id]) if options[:task_results].present?
        add_tasks_to_result(res, options[:task_ids]) if options[:task_ids].present?
        add_parent_href_to_result(res, options[:parent_id]) if options[:parent_id].present?
        res
      end

      def add_href_to_result(hash, type, id)
        hash[:href] = "#{@req.api_prefix}/#{type}/#{id}"
        hash
      end

      def add_parent_href_to_result(hash, parent_id = nil)
        return hash if hash[:href].present?

        hash[:href] = "#{@req.api_prefix}/#{@req.collection}/#{parent_id ? parent_id : @req.collection_id}"
        hash
      end

      def add_task_to_result(hash, task_id)
        hash[:task_id]   = task_id.to_s
        hash[:task_href] = task_href(task_id)
        hash
      end

      def add_tasks_to_result(hash, task_ids)
        add_task_to_result(hash, task_ids.first)
        hash[:tasks] = task_ids.collect do |task_id|
          { :id => task_id.to_s, :href => task_href(task_id) }
        end
      end

      def add_tag_to_result(hash, tag_spec)
        hash[:tag_category] = tag_spec[:category] if tag_spec[:category].present?
        hash[:tag_name]     = tag_spec[:name] if tag_spec[:name].present?
        hash[:tag_href]     = "#{@req.api_prefix}/tags/#{tag_spec[:id]}" if tag_spec[:id].present?
        hash
      end

      def add_task_results_href_to_result(hash, task_id)
        hash[:task_results_href] = "#{@req.api_prefix}/tasks/#{task_id}/task_results"
        hash
      end

      def task_href(task_id)
        "#{@req.api_prefix}/tasks/#{task_id}"
      end

      def add_subcollection_resource_to_result(hash, ctype, object)
        return hash if object.blank?
        ctype_pref = ctype.to_s.singularize
        hash["#{ctype_pref}_id".to_sym]   = object.id
        hash["#{ctype_pref}_href".to_sym] = "#{@req.api_prefix}/#{ctype}/#{object.id}"
        hash
      end

      def add_report_result_to_result(hash, result_id)
        hash[:result_id] = result_id
        hash[:result_href] = "#{@req.api_prefix}/results/#{result_id}"
        hash
      end

      def add_report_schedule_to_result(hash, schedule_id, report_id)
        hash[:schedule_id] = schedule_id
        hash[:schedule_href] = "#{@req.api_prefix}/reports/#{report_id}/schedules/#{schedule_id}"
        hash
      end

      def log_result(hash)
        hash.each { |k, v| api_log_info("Result: #{k}=#{v}") }
      end
    end
  end
end
