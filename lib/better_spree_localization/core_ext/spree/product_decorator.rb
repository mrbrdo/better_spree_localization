module BetterSpreeLocalization
  module CoreExt
    module Spree
      module ProductDecorator
        module ClassMethods
          def search_by_name_or_sku(query)
            helper = SpreeMobility::TranslationQuery.new(all.model.mobility_backend_class(:name))

            helper.add_joins(self.all).
            joins(:variants_including_master).
            where("(LOWER(#{helper.col_name(:name)}) LIKE LOWER(:query)) OR (LOWER(#{::Spree::Variant.table_name}.sku) LIKE LOWER(:query))", query: "%#{query}%").distinct
          end
        end

        def self.prepended(base)
          base.whitelisted_ransackable_scopes << 'search_by_name_or_sku'
        end
      end
    end
  end
end