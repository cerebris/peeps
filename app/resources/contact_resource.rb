require 'jsonapi/resource'

class ContactResource < JSONAPI::Resource
  attributes :id, :name_first, :name_last, :email, :twitter
  has_many :phone_numbers
end
