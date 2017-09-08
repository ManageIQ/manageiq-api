module Api
  class PingController < ActionController::API
    def index
      render :plain => 'pong'
    end
  end
end
