module BetterSpreeLocalization
  module CoreExt
    module Spree
      module ProductDecorator
        module ClassMethods
          def search_by_name_or_sku(query)
            all.where(id:
              all.joins(:variants_including_master).like_any([:name], [query]) { |conditions|
                conditions + [
                  sanitize_sql_array(["LOWER(#{::Spree::Variant.table_name}.sku) LIKE ?", "%#{query&.downcase}%"])
                ]
              }.select(:id))
          end
        end

        def self.prepended(base)
          base.whitelisted_ransackable_scopes << 'search_by_name_or_sku'
        end
      end
    end
  end
end
