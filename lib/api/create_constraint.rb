module Api
  class CreateConstraint
    def matches?(request)
      Hash(JSON.parse(request.body.read)).fetch("action", "create").in?(%w(create add))
    ensure
      request.body.rewind
    end
  end
end
