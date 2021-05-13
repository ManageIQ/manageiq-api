describe 'API configuration (config/api.yml)' do
  let(:api_settings) { Api::ApiConfig }

  describe 'collections' do
    let(:collection_settings) { api_settings.collections }

    it "is sorted a-z" do
      actual = collection_settings.keys
      expected = collection_settings.keys.sort
      expect(actual).to eq(expected)
    end

    describe 'collection' do
      it 'each primary collection has an identifier for GET read action except for a few' do
        whitelisted = collection_settings.find_all do |_, v|
          v.options.index(:collection) &&
            v.collection_actions&.[](:get)&.find { |h| h[:name] == 'read' }&.identifier.nil?
        end.map(&:first).sort
        expect(whitelisted).to eq(%i[automate_workspaces currencies features measures notifications pictures])
      end
    end

    describe 'identifiers' do
      let(:api_feature_identifiers) do
        collection_settings.each_with_object(Set.new) do |(_key, config), ids|
          action_configs  = config.to_h.select { |k, v| k.to_s.end_with?("_actions") }.values
          action_configs += Array(config.resource_entities).map { |e| Array(e.entity_actions) }

          action_configs.each do |action_config|
            action_config.each do |_verb, actions|
              actions.each do |action|
                ids.merge(Array(action[:identifier]))
                ids.merge(Array(action[:identifiers]).flat_map { |i| Array(i[:identifier]) })
              end
            end
          end

          ids.merge(Array(config[:identifier]))
        end
      end

      it 'is not empty' do
        expect(api_feature_identifiers).not_to be_empty
      end

      it 'contains only valid MiqProductFeature identifiers' do
        MiqProductFeature.seed_features
        invalid_features = api_feature_identifiers - MiqProductFeature.pluck(:identifier)
        expect(invalid_features).to be_empty
      end
    end
  end
end
