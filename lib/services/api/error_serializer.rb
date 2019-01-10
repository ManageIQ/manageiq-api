module Api
  class ErrorSerializer
    attr_reader :kind, :error

    SQL_STATEMENTS = " SELECT | UPDATE | INSERT | DELETE ".freeze

    def initialize(kind, error)
      @kind = kind
      @error = error
    end

    def serialize(no_sql_query = false)
      result = {
        :error => {
          :kind    => kind,
          :message => error.message,
          :klass   => error.class.name
        }
      }
      result[:error][:message] = remove_sql_query(error.message) if no_sql_query
      result[:error][:backtrace] = error.backtrace.join("\n") if Rails.env.test?
      result
    end

    private

    def remove_sql_query(message)
      return message unless message =~ /PG.*ERROR/i
      message.split(/#{SQL_STATEMENTS}/i)[0]
    end
  end
end
