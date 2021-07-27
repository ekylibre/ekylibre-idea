# frozen_string_literal: true

module Idea
  class Engine < ::Rails::Engine

    initializer :idea_i18n do |app|
      app.config.i18n.load_path += Dir[Idea::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :idea_extend_navigation do |_app|
      Idea::ExtNavigation.add_navigation_xml_to_existing_tree
    end

    initializer :idea_restfully_manageable do |app|
      app.config.x.restfully_manageable.view_paths << Idea::Engine.root.join('app', 'views')
    end

    initializer :hack_idea_javascript do
      tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
      tmp_file.open('a') do |f|
        import = '#= require duke_integration'
        f.puts(import) unless tmp_file.open('r').read.include?(import)
      end
    end

    initializer :hack_idea_stylesheets do
      tmp_file = Rails.root.join('tmp', 'plugins', 'theme-addons', 'themes', 'tekyla', 'plugins.scss')
      tmp_file.open('a') do |f|
        import = '@import "idea/main.scss";'
        f.puts(import) unless tmp_file.open('r').read.include?(import)
      end
    end

  end
end
