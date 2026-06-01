Rails.application.routes.draw do
  resources :flashcards

  with_options only: :show do
    resource :review
    resource :stats
    resources :character_entries
  end

  patch "review/preferences", to: "reviews#preferences"
  patch "review/:flashcard_id", to: "reviews#update", as: :review_flashcard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
