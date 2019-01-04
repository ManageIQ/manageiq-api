module Api
  class ErrorSerializer
    attr_reader :kind, :error

    def initialize(kind, error)
      @kind = kind
      @error = error
    end

    def serialize(remove_sql_select = false)
      result = {
        :error => {
          :kind    => kind,
          :message => error.message,
          :klass   => error.class.name
        }
      }
      result[:error][:message] = error.message.split(/ SELECT /i)[0] if remove_sql_select
      result[:error][:backtrace] = error.backtrace.join("\n") if Rails.env.test?
      result
    end
  end
end
