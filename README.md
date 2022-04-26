# Better Spree Localization

This gem provides some improvements over default Spree localization:

* will change locale of Product/Taxon slug when changing locale in the frontend
* will try to keep locale in the URL while browsing the frontend instead of randomly changing back to default locale
* will keep locale with Devise URLs (login, logout etc) and reset password
* will use correct locale in emails as was saved with the Order
* it works with `spree_mobilize` gem instead of `spree_globalize`, because it provides more complete features
* admin product search will additionally search by product SKU (including partial match)
* frontend search will additionally search by product SKU, but only on exact match (case-insensitive)

## Installation

1. Add this extension to your Gemfile with this line:

        gem 'better_spree_localization', github: 'mrbrdo/better_spree_localization'

2. Install the gem using Bundler:

        bundle install

3. Restart your server

        If your server was running, restart it so that it can find the assets properly.
