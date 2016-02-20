Rails.application.routes.draw do
  sso_devise

  if Rails.env.staging? or Rails.env.production?
    root 'pages#basic_income'
  else
    root 'pages#home'
  end

  resources :issues do
    resources :watches do
      delete :cancel, on: :collection
    end
  end

  resources :posts, only: [] do
    shallow do
      resources :comments
      resources :votes
      resources :likes do
        delete :cancel, on: :collection
      end
    end
  end
  get 'likes', to: "likes#by_me", as: 'likes_by_me'

  resources :articles
  resources :opinions

  get 'home', to: "pages#home", as: 'home'
  get '/i/:slug', to: "issues#slug", as: 'slug_issue'
  get '/tags/:name', to: "tags#show", as: 'show_tag'
end
