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
                # The new default order should put first the
                # results matching SKU (exactly), then results matching name,
                # and then results matching description.
                # To supports this, we do each search as its own subquery, and
                # expose a _search_order number for each subquery on which we
                # can sort.
                # The subqueries are joined through UNION, and the highest
                # _search_order for each products.id is selected with GROUP BY.
                # It is necessary to use DISTINCT on the final result set.
                products_table = ::Spree::Product.table_name
                subqueries = [
                  base_scope.joins(:variants_including_master).
                    where(::Spree::Variant.arel_table[:sku].
                      lower.eq(query&.downcase)),
                  base_scope.like_any([:name], [query]),
                  base_scope.like_any([:description], [query])
                ]

                subqueries_sql = subqueries.map.with_index do |query,idx|
                  query.select(query.arel.projections, "#{idx} AS _search_order").to_sql
                end

                union_scope = ::Spree::Product.from("(#{subqueries_sql.join(' UNION ')}) AS #{products_table}")
                product_ids_with_best_order =
                  union_scope.group(:id).
                  select(:id, "MIN(_search_order) AS _search_order")

                base_scope =
                  ::Spree::Product.joins(
                    "INNER JOIN (#{product_ids_with_best_order.to_sql})" \
                    " AS search_results ON " \
                    "#{products_table}.id = search_results.id")
              end
              base_scope
            end
          end
        end
      end
    end
  end
end
