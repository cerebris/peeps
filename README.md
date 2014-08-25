# Peeps: A demo of JSONAPI-Resources

Peeps is a very basic contact management system implemented as an API that follows the JSON API spec. 

Other apps will soon be written to demonstrate writing a consumer for this API.

The instructions below were used to create this app.


## Initial Steps to create this app

### Create a new Rails application

```
rails new peeps --skip-javascript
```

or

```
rails new peeps -d postgresql --skip-javascript
```

### Create the databases

```
rake db:create
```

### Add the JSONAPI-Resources gem
Add the gem to your Gemfile

```
gem 'jsonapi-resources'
```

Then bundle

```
bundle
```

### Derive Application Controller from JSONAPI::ResourceController
Make the following changes to application_controller.rb

```
require 'jsonapi/resource_controller'

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

```
  # Eager load code on boot so JSONAPI-Resources resources are loaded and processed globally
  config.eager_load = true
```



```
config.consider_all_requests_local       = false
```

This will prevent the server from returning the HTML formatted error messages when an exception happens. Not strictly
necessary, but it makes for nicer output when debugging using curl or a client library.

## Now let's put some meat into the app

### Create Models for our data
Use the standard rails generator to create a model for Contacts and one for related PhoneNumbers

```
rails g model Contact name_first:string name_last:string email:string twitter:string
```

Edit the model
```
class Contact < ActiveRecord::Base
  has_many :phone_numbers
end
```

Create the PhoneNumber model
```
rails g model PhoneNumber contact_id:integer name:string phone_number:string
```

Edit it

```
class PhoneNumber < ActiveRecord::Base
  belongs_to :contact
end
```

### Migrate the DB

```
rake db:migrate
```

### Create Controllers
Use the rails generator to create empty controllers. These will be inherit methods from the ResourceController so
they will know how to respond to the standard REST methods.

```
rails g controller Contacts --skip-assets
rails g controller PhoneNumbers --skip-assets
```

### Create our resources directory

We need a directory to hold our resources. Let's put in under our app directory

```
mkdir app/resources
```

### Create the resources

Create a new file for each resource. This must be named in a standard way so it can be found. This should be the single
underscored name of the model with \_resource.rb appended. For Contacts this will be contact_resource.rb.

Make the two resource files

contact_resource.rb

```
require 'jsonapi/resource'

class ContactResource < JSON::API::Resource
  attributes :id, :name_first, :name_last, :email, :twitter
  has_many :phone_numbers
end
```

and phone_number_resource.rb

```
require 'jsonapi/resource'

class PhoneNumberResource < JSONAPI::Resource
  attributes :id, :contact_id, :name, :phone_number
  has_one :contact

  filter :contact_id
end

```

### Setup routes
Require jsonapi/routing_ext 

```
require 'jsonapi/routing_ext'
```

Add the routes for the new resources

```
jsonapi_resources :contacts
jsonapi_resources :phone_numbers
```


## Test it out

Launch the app

```
rails server
```

Create a new contact
```
curl -i -H "Accept: application/json" -H 'Content-Type:application/json' -X POST -d '{"contacts": {"name_first":"John", "name_last":"Doe", "email":"john.doe@boring.test"}}' http://localhost:3000/contacts
```

You should get something like this back
```
HTTP/1.1 201 Created
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Ua-Compatible: chrome=1
Content-Type: application/json; charset=utf-8
Etag: "f53782c69bd6748c5a69254e92bca7ec"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: d8475c6a-ba4d-48a4-b41d-6f1144fcc8cb
X-Runtime: 0.070850
Server: WEBrick/1.3.1 (Ruby/2.1.1/2014-02-24)
Date: Tue, 03 Jun 2014 21:52:05 GMT
Content-Length: 136
Connection: Keep-Alive

{"contacts":[{"id":1,"name_first":"John","name_last":"Doe","email":"john.doe@boring.test","twitter":null,"links":{"phone_numbers":[]}}]}
```

You can now create a phone number for this contact

```
curl -i -H "Accept: application/json" -H 'Content-Type:application/json' -X POST -d '{"phone_numbers": {"contact_id":"1", "name":"home", "phone_number":"(603) 555-1212"}}' "http://localhost:3000/phone_numbers"
```

And you should get back something like this:

```
HTTP/1.1 201 Created
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Ua-Compatible: chrome=1
Content-Type: application/json; charset=utf-8
Etag: "6e11338169a479367027dc7ba03a706e"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 0b7cfd59-7fd0-4a31-ab95-2fdbb1352b4e
X-Runtime: 0.022276
Server: WEBrick/1.3.1 (Ruby/2.1.1/2014-02-24)
Date: Tue, 03 Jun 2014 21:56:10 GMT
Content-Length: 111
Connection: Keep-Alive

{"phone_numbers":[{"id":1,"contact_id":4,"name":"home","phone_number":"(603) 555-1212","links":{"contact":4}}]}
```

You can now query all one of your contacts

```
curl -i -H "Accept: application/json" "http://localhost:3000/contacts"
```

And you get this back:

```
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Ua-Compatible: chrome=1
Content-Type: application/json; charset=utf-8
Etag: "ef778cd5d944b904993aa7d3fd552c6e"
Cache-Control: max-age=0, private, must-revalidate
X-Request-Id: 009bb302-e3bc-41a0-a74d-1947d5e98b20
X-Runtime: 0.003116
Server: WEBrick/1.3.1 (Ruby/2.1.1/2014-02-24)
Date: Tue, 03 Jun 2014 21:58:04 GMT
Content-Length: 137
Connection: Keep-Alive

{"contacts":[{"id":4,"name_first":"John","name_last":"Doe","email":"john.doe@boring.test","twitter":null,"links":{"phone_numbers":[1]}}]}
```

Note that the phone_number id is included in the links, but not the details of the phone number. You can get these by
setting an include:

```
curl -i -H "Accept: application/json" "http://localhost:3000/contacts?include=phone_numbers"
```

and some fields:
```
curl -i -H "Accept: application/json" "http://localhost:3000/contacts?include=phone_numbers&fields%5Bcontacts%5D=name_first,name_last&fields%5Bphone_numbers%5D=name"
```


Test a validation Error
```
curl -i -H "Accept: application/json" -H 'Content-Type:application/json' -X POST -d '{"contacts": {"name_first":"John Doe", "email":"john.doe@boring.test"}}' http://localhost:3000/contacts
```
