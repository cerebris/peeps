# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

contacts = []
20.times do
  contacts << Contact.create({
    name_first: Faker::Name.first_name,
    name_last: Faker::Name.last_name,
    email: Faker::Internet.safe_email,
    twitter: "@#{Faker::Internet.user_name}"
  })
end

contacts.each do |contact|
  contact.phone_numbers.create({
    name: 'cell',
    phone_number: Faker::PhoneNumber.cell_phone
  })
end

