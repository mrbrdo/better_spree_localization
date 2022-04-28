module BetterSpreeLocalization
  module CoreExt
    module Spree
      module OrderDecorator
        def self.prepended(base)
          base.before_create :set_locale
        end

        private
        def set_locale
          self.locale = I18n.locale
        end
      end
    end
  end
end
