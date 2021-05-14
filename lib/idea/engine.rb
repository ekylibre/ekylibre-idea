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

  end
end
