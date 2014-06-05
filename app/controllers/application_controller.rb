require 'json/api/resource_controller'

class ApplicationController < JSON::API::ResourceController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
end