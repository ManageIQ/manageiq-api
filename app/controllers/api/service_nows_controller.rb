module Api
  class ServiceNowsController < BaseController

    def create_resource(type, _id, data)
      snow_user = data['username']
      snow_server = data['domain']
      table_name = data['table']
      snow_password = data['password']

      uri = "https://#{snow_server}/api/now/table/#{table_name}"

      payload = {
        :subject           => data['subject'],
        :details              => data['details']
      }


      headers = {
        :content_type  => 'application/json',
        :accept        => 'application/json',
        :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
      }

      request = RestClient::Request.new(
        :method  => :post,
        :url     => uri,
        :headers => headers,
        :payload => payload.to_json
      )

      rest_result = request.execute

      json_parse = JSON.parse(rest_result)
      result = json_parse['result']
     end

    def connect_resource(type, _id, data)
      snow_user = data['username']
      snow_server = data['domain']
      snow_password = data['password']
      table_name = data['table']
      uri = "https://#{snow_server}/api/now/table/#{table_name}"


      headers = {
        :content_type  => 'application/json',
        :accept        => 'application/json',
        :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
      }

      request = RestClient::Request.new(
        :method  => :get,
        :url     => uri,
        :headers => headers,
      )

      rest_result = request.execute

      json_parse = JSON.parse(rest_result)
      result = json_parse['result']
      aa=Authentication.new(:name=>"service now", :userid=>snow_user, :password=>snow_password, :options=>{:domain=>snow_server,:table=>table_name})
      aa.save
    end

    def update_collection(type, data)
      snow_user = data['username']
      snow_server = data['domain']
      snow_password = data['password']
      table_name = data['table']
      uri = "https://#{snow_server}/api/now/table/#{table_name}"


      payload = {
        :subject           => 'virtual',
        :details              => 'name'
      }


      headers = {
        :content_type  => 'application/json',
        :accept        => 'application/json',
        :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
      }

      request = RestClient::Request.new(
        :method  => :post,
        :url     => uri,
        :headers => headers,
        :payload => payload.to_json
      )

      rest_result = request.execute

      json_parse = JSON.parse(rest_result)
      result = json_parse['result']
     end

    def read_resource(type, _id, data)
      assert_id_not_specified(data, type)
      collection_class(type).create_firmware_registry(data.symbolize_keys)
    end
  end
end
