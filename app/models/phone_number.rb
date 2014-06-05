class PhoneNumber < ActiveRecord::Base
  has_one :contact
end
