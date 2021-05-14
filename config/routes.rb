# frozen_string_literal: true

Rails.application.routes.draw do

  concern :list do
    get :list, on: :collection
  end

  namespace :backend do
    resources :idea_diagnostics, concerns: %i[list]
    resources :idea_diagnostic_results, concerns: %i[list]
  end

end
