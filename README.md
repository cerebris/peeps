# Peeps: A demo of JSONAPI-Resources

Peeps is a very basic contact management system implemented as an API that follows the JSON API spec.

Other apps will soon be written to demonstrate writing a consumer for this API.

The instructions below were used to create this app.


## Initial Steps to create this app

### Create a new Rails application

```bash
rails new peeps --skip-javascript
```

or

```bash
rails new peeps -d postgresql --skip-javascript
```

### Create the databases

```bash
rake db:create
```

### Add the JSONAPI-Resources gem
Add the gem to your Gemfile

```bash
gem 'jsonapi-resources'
```

Then bundle

```bash
bundle
```

### Application Controller 
Make the following changes to application_controller.rb

```ruby
class ApplicationController < ActionController::Base
  include JSONAPI::ActsAsResourceController
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
end
```

OR

```ruby
class ApplicationController < JSONAPI::ResourceController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
end
```

You can also do this on a per controller basis in your app, if only some controllers will serve the API.

### Configure Development Environment
Edit config/environments/development.rb

Eager loading of classes is recommended. The code will work without it, but I think it's the right way to go.
See http://blog.plataformatec.com.br/2012/08/eager-loading-for-greater-good/

```ruby
  # Eager load code on boot so JSONAPI-Resources resources are loaded and processed globally
  config.eager_load = true
```

```ruby
config.consider_all_requests_local       = false
```

This will prevent the server from returning the HTML formatted error messages when an exception happens. Not strictly
necessary, but it makes for nicer output when debugging using curl or a client library.

### CORS - optional

You might run into CORS issues when accessing from the browser. You can use the `rack-cors` gem to allow sharing across 
origins. See [https://github.com/cyu/rack-cors](https://github.com/cyu/rack-cors) for more details.

Add the gem to your Gemfile

```bash
gem 'rack-cors'
```

Add the CORS middleware to your `config/application.rb`:

```rb
# Example only, please understand CORS before blindly adding this configuration
# This is not enabled in the peeps source code.
module Peeps
  class Application < Rails::Application
    config.middleware.insert_before 0, 'Rack::Cors', :debug => !Rails.env.production?, :logger => (-> { Rails.logger }) do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :patch, :delete, :options]
      end
    end
  end
end

```

## Now let's put some meat into the app

### Create Models for our data
Use the standard rails generator to create a model for Contacts and one for related PhoneNumbers

```bash
rails g model Contact name_first:string name_last:string email:string twitter:string
```

Edit the model
```ruby
class Contact < ActiveRecord::Base
  has_many :phone_numbers

  ### Validations
  validates :name_first, presence: true
  validates :name_last, presence: true

end
```

Create the PhoneNumber model
```bash
rails g model PhoneNumber contact_id:integer name:string phone_number:string
```

Edit it

```ruby
class PhoneNumber < ActiveRecord::Base
  belongs_to :contact
end
```

### Migrate the DB

```bash
rake db:migrate
```

### Create Controllers
Use the rails generator to create empty controllers. These will be inherit methods from the ResourceController so
they will know how to respond to the standard REST methods.

```bash
rails g controller Contacts --skip-assets
rails g controller PhoneNumbers --skip-assets
```

### Create our resources directory

We need a directory to hold our resources. Let's put in under our app directory

```bash
mkdir app/resources
```

### Create the resources

Create a new file for each resource. This must be named in a standard way so it can be found. This should be the single
underscored name of the model with \_resource.rb appended. For Contacts this will be contact_resource.rb.

Make the two resource files

contact_resource.rb

```ruby
class ContactResource < JSONAPI::Resource
  attributes :name_first, :name_last, :email, :twitter
  has_many :phone_numbers
end
```

and phone_number_resource.rb

```ruby
class PhoneNumberResource < JSONAPI::Resource
  attributes :name, :phone_number
  has_one :contact

  filter :contact
end

```

### Setup routes

Add the routes for the new resources

```ruby
jsonapi_resources :contacts
jsonapi_resources :phone_numbers
```


## Test it out

Launch the app

```bash
rails server
```

Create a new contact
```bash
curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{"data": {"type":"contacts", "attributes":{"name-first":"John", "name-last":"Doe", "email":"john.doe@boring.test"}}}' http://localhost:3000/contacts
```

You should get something like this back
```
HTTP/1.1 201 Created
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/vnd.api+json
Etag: W/"809b88231e24ed1f901240f47278700d"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: e4a991a3-555b-42ac-af1e-f103a1007edc
X-Runtime: 0.151446
Server: WEBrick/1.3.1 (Ruby/2.2.2/2015-04-13)
Date: Thu, 18 Jun 2015 18:21:21 GMT
Content-Length: 363
Connection: Keep-Alive

{"data":{"id":"1","type":"contacts","links":{"self":"http://localhost:3000/contacts/1"},"attributes":{"name-first":"John","name-last":"Doe","email":"john.doe@boring.test","twitter":null},"relationships":{"phone-numbers":{"links":{"self":"http://localhost:3000/contacts/1/relationships/phone-numbers","related":"http://localhost:3000/contacts/1/phone-numbers"}}}}}
```

You can now create a phone number for this contact

```
curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{ "data": { "type": "phone-numbers", "relationships": { "contact": { "data": { "type": "contacts", "id": "1" } } }, "attributes": { "name": "home", "phone-number": "(603) 555-1212" } } }' http://localhost:3000/phone-numbers
```

And you should get back something like this:

```
HTTP/1.1 201 Created
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/vnd.api+json
Etag: W/"b8d0ce0fd869a38dfb812c5ac1afa94e"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 63920c97-247a-43e7-9fe3-87ede9e84bb5
X-Runtime: 0.018539
Server: WEBrick/1.3.1 (Ruby/2.2.2/2015-04-13)
Date: Thu, 18 Jun 2015 18:22:13 GMT
Content-Length: 363
Connection: Keep-Alive

{"data":{"id":"1","type":"phone-numbers","links":{"self":"http://localhost:3000/phone-numbers/1"},"attributes":{"name":"home","phone-number":"(603) 555-1212"},"relationships":{"contact":{"links":{"self":"http://localhost:3000/phone-numbers/1/relationships/contact","related":"http://localhost:3000/phone-numbers/1/contact"},"data":{"type":"contacts","id":"1"}}}}}
```

You can now query all one of your contacts

```bash
curl -i -H "Accept: application/vnd.api+json" "http://localhost:3000/contacts"
```

And you get this back:

```
TTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/vnd.api+json
Etag: W/"512c3c875409b401c0446945bb40916f"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: b324bff8-8196-4c43-80fd-b2fd1f41c565
X-Runtime: 0.004106
Server: WEBrick/1.3.1 (Ruby/2.2.2/2015-04-13)
Date: Thu, 18 Jun 2015 18:23:19 GMT
Content-Length: 365
Connection: Keep-Alive

{"data":[{"id":"1","type":"contacts","links":{"self":"http://localhost:3000/contacts/1"},"attributes":{"name-first":"John","name-last":"Doe","email":"john.doe@boring.test","twitter":null},"relationships":{"phone-numbers":{"links":{"self":"http://localhost:3000/contacts/1/relationships/phone-numbers","related":"http://localhost:3000/contacts/1/phone-numbers"}}}}]}
```

Note that the phone_number id is included in the links, but not the details of the phone number. You can get these by
setting an include:

```bash
curl -i -H "Accept: application/vnd.api+json" "http://localhost:3000/contacts?include=phone-numbers"
```

and some fields:
```bash
curl -i -H "Accept: application/vnd.api+json" "http://localhost:3000/contacts?include=phone-numbers&fields%5Bcontacts%5D=name-first,name-last&fields%5Bphone-numbers%5D=name"
```

Test a validation Error
```bash
curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{ "data": { "type": "contacts", "attributes": { "name-first": "John Doe", "email": "john.doe@boring.test" } } }' http://localhost:3000/contacts
```

## Handling More Data

The earlier responses seem pretty snappy, but they are not really returning a lot of data. In a real world system there will be a lot more data. Lets mock some with the faker gem.

### Add fake data for testing

Add the `faker` gem to your Gemfile

```ruby
gem 'faker', group: [:development, :test]
```

And add some seed data using the seeds file

```ruby
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

```

Now lets add the seed data (note this may run for a while):

```bash
bundle install
rails db:seed
```

### Large requests take to long to complete

Now if we query our contacts we will get a large (20K contacts) dataset back, and it may run for many seconds (about 8 on my system)

```bash
curl -i -H "Accept: application/vnd.api+json" "http://localhost:3000/contacts"
```

### Options

There are some things we can do to work around this. First we should add a config file to our initializers. Add a file named `jsonapi_resources.rb` to the `config/initializers` directory and add this:

```ruby
JSONAPI.configure do |config|
  # Config setting will go here
end
```

#### Caching

We can enable caching so the next request will not require the system to process all 20K records again.

We first need to turn on caching for the rails portion of the application with the following:

```bash
rails dev:cache
```

To enable caching of JSONAPI responses we need to specify which cache to use (and in version v0.10.x and later that we want all resources cached by default). So add the following to the initializer you created earlier:

```ruby
JSONAPI.configure do |config|
  config.resource_cache = Rails.cache
  # The following option works in versions v0.10 and later
  #config.default_caching = true
 end 
```

If using an earlier version than v0.10.x we need to enable caching for each resource type we want the system to cache. Add the following line to the `contacts` ressource:

```ruby
class ContactResource < JSONAPI::Resource
  caching
  #...
end
```

If we restart the application and make the same request it will still take the same amount of time (actually a tiny bit more as the resources are added to the cache). However if we perform the same request the time should drop significantly, going from ~8s to ~1.6s on my system for the same 20K contacts.

We might be able to live with performance of the cached results, but we should plan for the worst case. So we need another solution to keep our responses snappy.

#### Pagination

Instead of returning the full result set when the user asks for it, we can break it into smaller pages of data. That way the server never needs to serialize every resource in the system at once.

We can add pagination with a config option in the initializer. Add the following to `config/initializers/jsonapi_resources.rb`:

```ruby
JSONAPI.configure do |config|
  config.resource_cache = Rails.cache
  # config.default_caching = true

  # Options are :none, :offset, :paged, or a custom paginator name
  config.default_paginator = :paged # default is :none

  config.default_page_size = 50 # default is 10
  config.maximum_page_size = 100 # default is 20 
end
```

Restart the system and try the request again:

```bash
curl -i -H "Accept: application/vnd.api+json" "http://localhost:3000/contacts"
```


Now we only get the first 50 contacts back, and the request is much faster (about 80ms). And you will now see a `links` key with links to get the remaining resources in your set. This should look like this:

```json
{
    "data":[...],
    "links": {
    "first":"http://localhost:3000/contacts?page%5Bnumber%5D=1&page%5Bsize%5D=50",
    "next":"http://localhost:3000/contacts?page%5Bnumber%5D=2&page%5Bsize%5D=50",
    "last":"http://localhost:3000/contacts?page%5Bnumber%5D=401&page%5Bsize%5D=50",
    }
}
```

This will allow your client to iterate over the `next` links to fetch the full results set without putting extreme pressure on your server.

The `default_page_size` setting is used if the request does not specify a size, and the `maximum_page_size` is used to limit the size the client may request.

*Note:* The default page sizes are very conservative. There is significant overhead in making many small requests, and tuning the page sizes should be considered essential. 