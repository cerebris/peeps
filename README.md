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

### Derive Application Controller from JSONAPI::ResourceController
Make the following changes to application_controller.rb

```ruby
class ApplicationController < JSONAPI::ResourceController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
end
```

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
  has_one :contact
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
curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{"data": {"type":"contacts", "name-first":"John", "name-last":"Doe", "email":"john.doe@boring.test"}}' http://localhost:3000/contacts
```

You should get something like this back
```
HTTP/1.1 201 Created
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/vnd.api+json
Etag: W/"aba27b88b6c51f0910ec995ab613e679"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 998edda8-e29a-4dfa-ad68-2b524d660aa7
X-Runtime: 0.147099
Server: WEBrick/1.3.1 (Ruby/2.2.0/2014-12-25)
Date: Thu, 19 Mar 2015 22:28:15 GMT
Content-Length: 312
Connection: Keep-Alive

{"data":{"id":"1","name-first":"John","name-last":"Doe","email":"john.doe@boring.test","twitter":null,"type":"contacts","links":{"self":"http://localhost:3000/contacts/1","phone-numbers":{"self":"http://localhost:3000/contacts/1/links/phone-numbers","related":"http://localhost:3000/contacts/1/phone-numbers"}}}}

```

You can now create a phone number for this contact

```
curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{"data": {"type":"phone-numbers", "links": {"contact": {"linkage": {"type": "contacts", "id":"1"}}}, "name":"home", "phone-number":"(603) 555-1212"}}' "http://localhost:3000/phone-numbers"
```

And you should get back something like this:

```
HTTP/1.1 201 Created
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/vnd.api+json
Etag: W/"2addda2f434de1f85a7997e1d6185a2b"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 18febd47-a3e5-471e-8f8b-adf0db6c68fb
X-Runtime: 0.018462
Server: WEBrick/1.3.1 (Ruby/2.2.0/2014-12-25)
Date: Thu, 19 Mar 2015 22:28:38 GMT
Content-Length: 315
Connection: Keep-Alive

{"data":{"id":"1","name":"home","phone-number":"(603) 555-1212","type":"phone_numbers","links":{"self":"http://localhost:3000/phone-numbers/1","contact":{"self":"http://localhost:3000/phone-numbers/1/links/contact","related":"http://localhost:3000/phone-numbers/1/contact","linkage":{"type":"contacts","id":"1"}}}}}
```

You can now query all one of your contacts

```bash
curl -i -H "Accept: application/vnd.api+json" "http://localhost:3000/contacts"
```

And you get this back:

```
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Content-Type: application/vnd.api+json
Etag: W/"577b17ec60006c68fb522a2af809132a"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 524e0eb7-fb0d-4d26-9ba2-627bb625ab25
X-Runtime: 0.003388
Server: WEBrick/1.3.1 (Ruby/2.2.0/2014-12-25)
Date: Thu, 19 Mar 2015 22:29:05 GMT
Content-Length: 314
Connection: Keep-Alive

{"data":[{"id":"1","name-first":"John","name-last":"Doe","email":"john.doe@boring.test","twitter":null,"type":"contacts","links":{"self":"http://localhost:3000/contacts/1","phone-numbers":{"self":"http://localhost:3000/contacts/1/links/phone-numbers","related":"http://localhost:3000/contacts/1/phone-numbers"}}}]}
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
curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{"data": {"type":"contacts", "name-first":"John Doe", "email":"john.doe@boring.test"}}' http://localhost:3000/contacts
```
