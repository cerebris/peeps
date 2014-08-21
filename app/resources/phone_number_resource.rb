require 'jsonapi/resource'

class PhoneNumberResource < JSONAPI::Resource
  attributes :id, :contact_id, :name, :phone_number
  has_one :contact

  filter :contact_id
end
