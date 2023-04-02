Rails.application.routes.draw do
  root to: 'chat#show'
  resources :chats
end
