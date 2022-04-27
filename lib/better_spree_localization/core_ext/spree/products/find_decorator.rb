module BetterSpreeLocalization
  module CoreExt
    module Spree
      module Products
        module FindDecorator
          private
          # Change default order for search results (see comment
          # in BaseDecorator::get_products_conditions_for)
          def ordered(products)
            if !sort_by? || sort_by == 'default'
              if taxons?
                products.ascend_by_taxons_min_position(taxons)
              else
                ordered_default(products)
              end
            else
              super
            end
          end

          def ordered_default(products)
            # Not the nicest way to check if join with _search_order is there,
            # but it works. Probably a little slow but nothing noticable.
            return products unless products.to_sql.include?('_search_order')
            products.
            select("#{::Spree::Product.table_name}.*, _search_order").
            order('_search_order')
          end
        end
      end
    end
  end
end
