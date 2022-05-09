ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      match('plugins/reftracker' => 'reftracker_offers#index', :via => [:get])
      match('plugins/reftracker/import' => 'reftracker_offers#import', :via => [:post])
    end
  end
end
