module Idea
  class Engine < ::Rails::Engine
    initializer 'idea.assets.precompile' do |app|
      app.config.assets.precompile += %w[*.js *.svg *.haml]
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Idea::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

  end
end
