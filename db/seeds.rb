# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

contacts = []
20000.times do
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

  contact.phone_numbers.create({
                                 name: 'home',
                                 phone_number: Faker::PhoneNumber.phone_number
                               })
end
