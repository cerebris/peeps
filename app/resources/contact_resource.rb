require 'json/api/resource'

class ContactResource < JSON::API::Resource
  attributes :id, :name_first, :name_last, :email, :twitter
  has_many :phone_numbers
end
