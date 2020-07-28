RSpec.shared_context "for 'expand' query optimizations" do
  context "expand attribute query optimizations" do
    let(:resource)  { :vms }
    let(:index_url) { api_vms_url }

    it "removes N+1's from the index query for subcollections/virtual_attributes" do
      api_basic_authorize action_identifier(resource, :read, :resource_actions, :get)

      expands    = ["resources"]
      from_match = [resource]

      if defined?(includes)
        expands    << includes
        from_match << includes
      end

      attrs                = defined?(attributes)  ? attributes  : "resources"
      query_match          = /SELECT.*FROM\s"(?:#{from_match.join("|")})"/m
      expected_query_count = defined?(query_count) ? query_count : 10

      expect {
        get index_url, :params => {
          :expand     => expands.join(','),
          :attributes => attrs
        }
      }.to make_database_queries(:count => expected_query_count, :matching => query_match)
    end
  end
end
