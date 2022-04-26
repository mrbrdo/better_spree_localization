module BetterSpreeLocalization
  module CoreExt
    module Spree
      module Core
        module Search
          module BaseDecorator
            protected

            # method should return new scope based on base_scope
            def get_products_conditions_for(base_scope, query)
              unless query.blank?
                base_scope = base_scope.joins(:variants_including_master).like_any([:name, :description], [query]) do |conditions|
                  conditions + [::Spree::Variant.arel_table[:sku].lower.eq(query&.downcase).to_sql]
                end
              end
              base_scope
            end
          end
        end
      end
    end
  end
end
