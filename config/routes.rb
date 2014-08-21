require 'jsonapi/routing_ext'

Peeps::Application.routes.draw do
  jsonapi_resources :contacts
  jsonapi_resources :phone_numbers
end
