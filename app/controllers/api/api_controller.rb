module Api
  class ApiController < Api::BaseController
    def options
      head(:ok)
    end

    def index
      res = {
        :name          => ApiConfig.base.name,
        :description   => ApiConfig.base.description,
        :version       => ManageIQ::Api::VERSION,
        :versions      => entrypoint_versions,
        :settings      => user_settings,
        :identity      => auth_identity,
        :server_info   => server_info,
        :product_info  => product_info_data
      }
      res[:authorization] = auth_authorization if attribute_selection.include?("authorization")
      res[:collections]   = entrypoint_collections
      render_resource :entrypoint, res
    end

    def product_info
      render_resource :product_info, product_info_data
    end

    private

    def entrypoint_versions
      Api::SUPPORTED_VERSIONS.collect do |version|
        {
          :name => version,
          :href => "#{@req.base}#{@req.prefix(false)}/v#{version}"
        }
      end
    end

    def auth_identity
      {
        :userid     => current_user.userid,
        :name       => current_user.name,
        :user_href  => "#{@req.api_prefix}/users/#{current_user.id}",
        :group      => current_group.description,
        :group_href => "#{@req.api_prefix}/groups/#{current_group.id}",
        :role       => current_group.miq_user_role_name,
        :role_href  => "#{@req.api_prefix}/roles/#{current_group.miq_user_role.id}",
        :tenant     => current_group.tenant.name,
        :groups     => current_user.miq_groups.pluck(:description),
        :miq_groups => normalize_array(miq_groups, :groups)
      }
    end

    def entrypoint_collections
      collection_config.collections_with_description.sort.collect do |collection_name, description|
        {
          :name        => collection_name,
          :href        => collection_name,
          :description => description
        }
      end
    end

    def server_info
      {
        :version         => Vmdb::Appliance.VERSION,
        :build           => Vmdb::Appliance.BUILD,
        :release         => Vmdb::Appliance.RELEASE,
        :appliance       => MiqServer.my_server.name,
        :time            => Time.now.utc.iso8601,
        :server_href     => "#{@req.api_prefix}/servers/#{MiqServer.my_server.id}",
        :zone_href       => "#{@req.api_prefix}/zones/#{MiqServer.my_server.zone.id}",
        :region_href     => "#{@req.api_prefix}/regions/#{MiqRegion.my_region.id}",
        :enterprise_href => "#{@req.api_prefix}/enterprises/#{MiqEnterprise.my_enterprise.id}",
        :plugins         => plugin_info
      }
    end

    def product_info_data
      {
        :name                 => Vmdb::Appliance.PRODUCT_NAME,
        :name_full            => I18n.t("product.name_full"),
        :copyright            => I18n.t("product.copyright"),
        :support_website      => ::Settings.docs.product_support_website,
        :support_website_text => ::Settings.docs.product_support_website_text,
        :branding_info        => branding_info
      }
    end

    def image_path(image)
      ActionController::Base.helpers.image_path(image)
    rescue Sprockets::FileNotFound # UI isn't loaded, we don't want images
      nil
    end

    def branding_info
      {
        :brand      => Settings.server.custom_brand ? image_path('/upload/custom_brand.png') : image_path('layout/brand.svg'),
        :logo       => Settings.server.custom_logo ? image_path('/upload/custom_logo.png') : image_path('layout/login-screen-logo.png'),
        :login_logo => Settings.server.custom_login_logo ? image_path('/upload/custom_login_logo.png') : nil,
        :favicon    => Settings.server.custom_favicon ? image_path('/upload/custom_favicon.ico') : image_path('favicon.ico')
      }.compact
    end

    def plugin_info
      Vmdb::Plugins.versions.each_with_object({}) do |(engine, version), hash|
        hash[engine.to_s] = {
          :display_name => engine.plugin_name,
          :version      => version
        }
      end
    end

    def miq_groups
      current_user.miq_groups.collect do |group|
        group.attributes.merge(
          :sui_product_features => group.sui_product_features,
          :product_features     => group.miq_product_features.map(&:identifier)
        )
      end
    end

    def current_group
      @group ||= current_user.current_group
    end

    def auth_authorization
      {
        :product_features => product_features(current_group.miq_user_role)
      }
    end

    def product_features(role)
      pf_result = {}
      role.feature_identifiers.each { |ident| add_product_feature(pf_result, ident) }
      pf_result
    end

    def add_product_feature(pf_result, ident)
      details  = MiqProductFeature.features[ident.to_s][:details]
      children = MiqProductFeature.feature_children(ident)
      add_product_feature_details(pf_result, ident, details, children)
      children.each { |child_ident| add_product_feature(pf_result, child_ident) }
    end

    def add_product_feature_details(pf_result, ident, details, children)
      ident_str = ident.to_s
      res = {
        "name"        => details[:name],
        "description" => details[:description]
      }
      collection, method, action = collection_config.what_refers_to_feature(ident_str)
      collections = collection_config.names_for_feature(ident_str)
      res["href"] = "#{@req.api_prefix}/#{collections.first}" if collections.one?
      res["action"] = api_action_details(collection, method, action) if collection.present?
      res["children"] = children if children.present?
      pf_result[ident_str] = res
    end

    def api_action_details(collection, method, action)
      {
        "name"   => action[:name],
        "method" => method,
        "href"   => "#{@req.api_prefix}/#{collection}"
      }
    end
  end
end
