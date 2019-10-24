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
        feature_identifiers { |set, id| set.add(id) }
      end

      let(:sui_product_features) do
        feature_identifiers { |set, id| set.add(id) if /^sui_/ =~ id }
      end

      it 'is not empty' do
        expect(api_feature_identifiers).not_to be_empty
      end

      it 'contains only valid miq_feature identifiers' do
        MiqProductFeature.seed_features
        dangling = Array(api_feature_identifiers).reject { |feature| MiqProductFeature.feature_exists?(feature) }
        expect(dangling).to be_empty
      end

      it 'contains valid sui specific miq_feature identifiers' do
        expect(sui_product_features.subset?(api_feature_identifiers))
      end

      def feature_identifiers
        collection_settings.each_with_object(Set.new) do |(_, cfg), set|
          Array(cfg[:identifier]).each { |id| set.add(id) }
          keys = %i(collection_actions resource_actions subcollection_actions subresource_actions)
          Array(cfg[:subcollections]).each do |s|
            keys << "#{s}_subcollection_actions" << "#{s}_subresource_actions"
          end
          keys.each do |action_type|
            next unless cfg[action_type]
            cfg[action_type].each_value do |_, method_cfg|
              method_cfg.each do |action_cfg|
                next unless action_cfg[:identifier]
                Array(action_cfg[:identifier]).each { |id| yield(set, id) }
              end
            end
          end
        end
      end
    end
  end
end
