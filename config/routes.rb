Rails.application.routes.draw do
  root to: 'home#index'

  resources :things do
    member do
      post :create_comment
      get :next_comments
    end
  end

  get  "sessions/sign_up_form"
  post "sessions/sign_up"
  get  "sessions/sign_out"

  post "sessions/sign_in"
  resources :sessions
end
