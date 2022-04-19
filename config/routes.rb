Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    # Using :only here so it doesn't redraw those routes
  end
end
