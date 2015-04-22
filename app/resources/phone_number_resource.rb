class PhoneNumberResource < JSONAPI::Resource
  attributes :name, :phone_number
  has_one :contact

  filter :contact
end
