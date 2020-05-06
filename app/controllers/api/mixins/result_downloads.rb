module Api
  module Mixins
    module ResultDownloads
      COMMON_SUPPORTED_RESULT_TYPES = %w[txt csv].freeze

      RESULT_TYPE_TO_CONTENT_TYPE = {
        "txt" => "application/text",
        "csv" => "application/csv",
        "pdf" => "application/pdf"
      }.freeze

      def supported_result_types
        @supported_result_types ||= begin
          supported_types = COMMON_SUPPORTED_RESULT_TYPES.dup
          supported_types << "pdf" if PdfGenerator.available?
          supported_types
        end
      end

      def validate_result_type(result_type)
        raise "Missing result_type" if result_type.blank?

        result_type = result_type.downcase
        raise "Unsupported result_type #{result_type} specified, must be one of #{supported_result_types.join(", ")}." unless supported_result_types.include?(result_type)

        result_type
      end
    end
  end
end
