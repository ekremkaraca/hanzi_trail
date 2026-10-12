Rails.application.routes.draw do
  resource :session
  resources :flashcards

  with_options only: :show do
    resource :review
    resource :stats
  end

  resources :character_entries, only: %i[show edit update destroy]

  patch "review/preferences", to: "reviews#preferences"
  patch "review/reset", to: "reviews#reset", as: :review_reset
  patch "review/:flashcard_id", to: "reviews#update", as: :review_flashcard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
