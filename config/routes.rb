Rails.application.routes.draw do
  resources :flashcards
  resource :review, only: :show
  patch "review/:flashcard_id", to: "reviews#update", as: :review_flashcard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
