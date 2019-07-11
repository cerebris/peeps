class PhoneNumberResource < JSONAPI::Resource
  caching

  attributes :name, :phone_number
  has_one :contact

  filter :contact
end
