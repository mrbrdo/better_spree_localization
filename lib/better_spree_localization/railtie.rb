module BetterSpreeLocalization
  class Railtie < Rails::Railtie
    initializer "better_spree_localization.init" do |app|
      Dir[File.join(__dir__, 'core_ext', '**', '*.rb')].each { |f| require f }
    end

    config.to_prepare do
      # improved search - by SKU, name and description
      ::Spree::Product.singleton_class.prepend BetterSpreeLocalization::CoreExt::Spree::ProductDecorator::ClassMethods
      ::Spree::Product.prepend BetterSpreeLocalization::CoreExt::Spree::ProductDecorator
      ::Spree::Core::Search::Base.prepend BetterSpreeLocalization::CoreExt::Spree::Core::Search::BaseDecorator
      ::Spree::Products::Find.prepend BetterSpreeLocalization::CoreExt::Spree::Products::FindDecorator
      Dir.glob(File.join(__dir__, 'overrides', '**', '*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # This will add before_action :set_locale (from locale param)
      class ::DeviseController
        include ::Spree::Core::ControllerHelpers::Locale
      end

      class ::Spree::UserMailer
        def reset_password_instructions(user, token, *_args)
          current_store_id = _args.inject(:merge)[:current_store_id]
          @current_store = ::Spree::Store.find(current_store_id) || ::Spree::Store.current

          # This would override our set_locale
          # @locale = @current_store.has_attribute?(:default_locale) ? @current_store.default_locale : I18n.default_locale
          # I18n.locale = @locale if @locale.present?
          @locale = ::I18n.locale

          @edit_password_reset_url = spree.edit_spree_user_password_url(reset_password_token: token, host: @current_store.url)
          @user = user

          mail to: user.email, from: from_address, subject: @current_store.name + ' ' + ::I18n.t(:subject, scope: [:devise, :mailer, :reset_password_instructions]), store_url: @current_store.url
        end
      end

      # set Order#locale to current locale on Order create
      ::Spree::Order.prepend BetterSpreeLocalization::CoreExt::Spree::OrderDecorator

      # better error handling & reporting only
      ::Spree::BaseHelper.class_eval do
        def seo_url(taxon, options = {})
          if taxon && taxon.permalink
            spree.nested_taxons_path(taxon.permalink, options.merge(locale: locale_param))
          elsif taxon
            Rollbar.error('seo_url for taxon without permalink', taxon: taxon)
            spree.nested_taxons_path(taxon.id, options.merge(locale: locale_param))
          else
            Rollbar.error('seo_url for nil taxon')
            root_path(locale: locale_param)
          end
        end
      end

      module UserSessionsControllerUseLocale
        def after_sign_in_redirect(resource_or_scope)
          stored_location_for(resource_or_scope) || account_path(locale: ::I18n.locale)
        end
      end
      ::Spree::UserSessionsController.send :prepend, UserSessionsControllerUseLocale

      module FixSpreeBaseMailerLocale
        private
        def set_email_locale
          # ActiveJob already forwards locale, but set it to order locale if we have it anyway
          if @order&.locale.present?
            ::I18n.locale = @order.locale
          end
        end
      end
      ::Spree::BaseMailer.send :prepend, FixSpreeBaseMailerLocale

      # NEW helper to link to cms page in current locale
      module ::Spree::MailHelper
        def link_to_page(page_code, *params)
          page = current_store.cms_pages.find_by(code: page_code, locale: ::I18n.locale)
          link_to page.title, spree.page_url(page.slug, locale: ::I18n.locale), *params
        end
      end

      # add option to pass params, so we can pass locale
      module ::Spree::AuthenticationHelpers
        def spree_login_path(*params, &block)
          spree.login_path(*spree_auth_path_params(params), &block)
        end

        def spree_signup_path(*params, &block)
          spree.signup_path(*spree_auth_path_params(params), &block)
        end

        def spree_logout_path(*params, &block)
          spree.logout_path(*spree_auth_path_params(params), &block)
        end

        def spree_auth_path_params(params)
          default = { locale: ::I18n.locale }
          if params.present?
            [default.merge(params.first), *params[1,100]]
          else
            [default]
          end
        end
      end

      # add locale to redirects in signin
      module DeviseFixRedirects
        private
        def after_sign_in_redirect(resource_or_scope)
          stored_location_for(resource_or_scope) || account_path(locale: ::I18n.locale)
        end

        def after_sign_out_redirect(resource_or_scope)
          super
          spree.login_path(locale: ::I18n.locale)
        end
      end
      ::Spree::UserSessionsController.send :prepend, DeviseFixRedirects
    end

    # URL locale patches
    config.after_initialize do
      Rails.application.reload_routes!
    
      [Rails.application, ::Spree::Core::Engine].each do |target|
        target_methods =
          target.routes.url_helpers.instance_methods.select do |meth|
            meth_s = meth.to_s
            # spree_path is used within other url helpers so we must not include it
            meth_s =~ /_path\z|_url\z/ && !meth_s.start_with?('api_') && !meth_s.include?('_api_') &&
              !meth_s.start_with?('admin_') && !meth_s.include?('_admin_') && meth_s != 'spree_path' &&
              !meth_s.start_with?('rails_')
          end
    
        patch_module = Module.new do
          target_methods.each do |meth|
            define_method meth do |*args, &block|
              args.push({}) if !args.last.kind_of?(Hash)
              args.last[:locale] ||= ::I18n.locale
              super(*args, &block)
            end
          end
    
          if target == Rails.application
            define_method :rails_storage_redirect_url do |*args, &block|
                if args.last.kind_of?(Hash)
                  args.last.delete(:locale)
                end
                super(*args, &block)
            end
            define_method :rails_blob_url do |*args, &block|
              if args.last.kind_of?(Hash)
                args.last.delete(:locale)
              end
              super(*args, &block)
            end
          end
        end
    
        target.routes.url_helpers.singleton_class.send :prepend, patch_module
      end
    end
    
    config.to_prepare do
      # Because we already patched _path helpers, spree_localized_link doesn't need to add locale
      module ::Spree
        module NavigationHelper
          def spree_localized_link(item)
            return if item.link.nil?
    
            output_locale = if locale_param
                              "/#{::I18n.locale}"
                            end
    
            if ['Spree::Product', 'Spree::Taxon', 'Spree::CmsPage'].include?(item.linked_resource_type)
              # changed here:
              if output_locale && item.link.start_with?(output_locale)
                item.link
              else
                output_locale.to_s + item.link
              end
            elsif item.linked_resource_type == 'Home Page'
              "/#{locale_param}"
            else
              item.link
            end
          end
        end
      end
    
      module SeoUrlLocaleFixer
        def generate_new_path(url:, locale:, default_locale_supplied:)
          unless supported_path?(url.path)
            return success(
              url: url,
              locale: locale,
              path: cleanup_path(url.path),
              default_locale_supplied: default_locale_supplied,
              locale_added_to_path: false
            )
          end
    
          new_path = nil
          if rails_path = recognize_path(url)
            current_store = find_current_store(url)
    
            if rails_path[:controller] == 'spree/products' && rails_path[:id].present?
              if new_id = model_attr_translation(locale, current_store.products, :slug, rails_path[:id])
                new_path =
                  spree_path_for(rails_path.merge(id: new_id, locale: locale))
              end
            elsif rails_path[:controller] == 'spree/taxons' && rails_path[:id].present?
              if new_id = model_attr_translation(locale, current_store.taxons, :permalink, rails_path[:id])
                new_path =
                  spree_path_for(rails_path.merge(id: new_id, locale: locale))
              end
            end
          end
    
          # default Spree logic
          unless new_path
            new_path =
              if default_locale_supplied
                maches_locale_regex?(url.path) ? url.path.gsub(::Spree::BuildLocalizedRedirectUrl::LOCALE_REGEX, '/') : url.path
              else
                maches_locale_regex?(url.path) ? url.path.gsub(::Spree::BuildLocalizedRedirectUrl::LOCALE_REGEX, "/#{locale}/") : "/#{locale}#{url.path}"
              end
            new_path = cleanup_path(new_path)
          end
    
          success(
            url: url,
            locale: locale,
            path: new_path,
            default_locale_supplied: default_locale_supplied,
            locale_added_to_path: true
          )
        end
    
        def initialize_url_object(url:, locale:, default_locale:)
          # Always append si-SL to / url on non-.si domain, even if it's the default
          # locale (because .eu always redirects / to /en/)
          uri = URI(url)
          if !defined?(::IpStoreRedirector) || uri.host.end_with?(::IpStoreRedirector::DEFAULT_DOMAIN)
            super
          else
            success(
              url: uri,
              locale: locale,
              default_locale_supplied: false
            )
          end
        end
    
        protected
    
        def model_attr_translation(new_locale, base_scope, attr, value)
          record = base_scope.find_by(attr => value)
          Mobility.with_locale(new_locale) { record.send(attr) } if record
        end
    
        def find_current_store(url)
          # Based on ControllerHelpers::Store
          current_store_finder = ::Spree::Dependencies.current_store_finder.constantize
          current_store_finder.new(url: url.host).execute
        end
    
        def spree_path_for(url_params)
          ::Spree::Core::Engine.routes.url_for(url_params.merge(only_path: true))
        end
    
        def recognize_path(url)
          ::Spree::Core::Engine.routes.recognize_path(url.path, method: 'GET')
        rescue ::ActionController::RoutingError
          nil
        end
      end
      ::Spree::BuildLocalizedRedirectUrl.send :prepend, SeoUrlLocaleFixer
    end
  end
end
