# Routes follow docs/Sagasu_Routes.pdf (# = user story number).
# Additions: item_groups#create, so a buyer can add a group by hand when the AI grouping misses one (story 6),
# and item_groups#edit, which renders the rename form inside a Turbo Frame (edit in place).
Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home" # 1, 2

  get "up" => "rails/health#show", as: :rails_health_check

  resources :projects, only: %i[index new create show] do # 3
    resources :items, only: [:create]                            # 4
    resources :item_groups, only: [:create] do                   # 6 (manual group)
      collection { post :generate }                              # 5 (AI)
    end
    resources :approvals, only: [:create]                        # 12
  end

  resources :items, only: %i[update destroy] # 4, 6

  resources :item_groups, only: %i[edit update] do               # 6 (edit in place, Turbo Frame)
    resources :group_suppliers, only: [:create] do               # 9
      collection { post :suggest }                               # 7 (AI)
    end
  end

  resources :group_suppliers, only: [:update]                    # 8

  resources :suppliers, only: %i[index show] do # 9, 10
    resources :reviews, only: [:create] # 11
  end

  resources :approvals, only: %i[index update] # 13, 14
end
