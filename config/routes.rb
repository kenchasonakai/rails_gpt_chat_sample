Rails.application.routes.draw do
  root to: 'chats#new'
  resources :chats
end
