module Api
  class CreateConstraint
    def matches?(request)
      body = request.body.read
      body.present? && Hash(JSON.parse(body)).fetch("action", "create").in?(%w[create add])
    ensure
      request.body.rewind
    end
  end
end
