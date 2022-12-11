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
  end
end
