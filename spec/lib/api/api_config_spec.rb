describe 'API configuration (config/api.yml)' do
  let(:api_settings) { Api::ApiConfig }

  describe 'collections' do
    let(:collection_settings) { api_settings.collections }

    it "is sorted a-z" do
      actual = collection_settings.keys
      expected = collection_settings.keys.sort
      expect(actual).to eq(expected)
    end

    describe 'identifiers' do
      let(:miq_product_features) do
        identifiers = Set.new
        each_product_feature { |f| identifiers.add(f[:identifier]) }
        identifiers
      end

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
        dangling = api_feature_identifiers - miq_product_features
        expect(dangling).to be_empty
      end

      it 'contains valid sui specific miq_feature identifiers' do
        expect(sui_product_features.subset?(api_feature_identifiers))
      end

      def all_product_features
        features = YAML.load_file("#{MiqProductFeature::FIXTURE_PATH}.yml")
        plugin_files = Vmdb::Plugins.flat_map do |plugin|
          Dir.glob("#{plugin.root.join(MiqProductFeature::RELATIVE_FIXTURE_PATH)}{.yml,.yaml,/*.yml,/*.yaml}")
        end
        plugin_files.each do |plugin|
          features[:children] += YAML.load_file(plugin)
        end

        features
      end

      def each_product_feature(feature = all_product_features, &block)
        yield(feature)
        Array(feature[:children]).each do |child|
          each_product_feature(child, &block)
        end
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
