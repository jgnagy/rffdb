Ruby Flat File DB
=================

About
-----
This is a really horrible idea for anything requiring high performance, but it is a pretty good way to demonstrate how to create a gem and simple framework in Ruby. This is meant to emulate ActiveRecord or DataMapper, without all the performance, scalabilty, and thread-safety concerns, and meant to be used with really poor database storage formats, like YAML. **Pay attention to this:** This is a demonstration of Ruby and frameworks, and not to be used in any kind of production environment.

The gem is currently built around the concepts of "documents" and "storage engines". The rffdb gem is built to allow defining and choosing "storage engines" per database model. Database models are subclasses of the `Document` class, and storage engines are subclasses of the `StorageEngine` class.

Usage
-----

Require the right gem(s):

    require 'rffdb'
  
The `Yaml` storage engine is included by default. To include additional storage engines (none currently exist), just require them:

    require 'rffdb/storage_engines/engine_name'

Now you must define a document model. Let's call this model "Product", like we're making an app to sell things:

    class Product < RubyFFDB::Document
    end

Now that's a pretty lame document, because all it has is an "id" attribute:

    product = Product.new
    product.id            # => 1

Let's start over, and this time make it better:

    class Product < RubyFFDB::Document
      attribute :name,        :class => String
      attribute :price,       :class => Float
      attribute :style,       :class => String
      attribute :description, :class => String
    end

Now our Product class can do more interesting things, like store data. Yay! Here's how we use it:

    product = Product.new
    product.name  = "Awesome Sauce 5000"
    product.price = 19.95
    product.style = "saucy"
    product.description = "A sauce above the rest. Easily 10x more awesome than any other sauce."
    product.commit    # or product.save

Now to pull it up later:

    product = Product.get(1)
    product.price     # => 19.95

If you suspect someone else has written to the file, or that it has otherwise changed since you last loaded it, just refresh it:

    product.refresh

If you want to make another model that uses a different storage engine, just specify the class when you define the model:

    class Customer < RubyFFDB::Document
      engine RubyFFDB::StorageEngines::MyAwesomeEngine  # default is RubyFFDB::StorageEngines::Yaml
      
      attribute :address,       :class => String
      attribute :first_name,    :class => String
      attribute :last_name,     :class => String
      attribute :phone_number,  :class => String
      attribute :email,         :class => String, :format => /[a-zA-Z0-9_.+-]{2,}[a-zA-Z0-9]@([a-zA-Z0-9_.+-]{2,}[a-zA-Z0-9])+/
    end
    
    customer = Customer.new
    customer.email = "abcd"
    #  RubyFFDB::Exceptions::InvalidInput raised

Whoa, see what just happened? We used a different storage engine, and we validated the format of email addresses! That's right, attributes support specifying a format for Strings using a regular expression. You can also have it execute arbitrary validations (defined in the model class) as long as they're methods that accept a single input: the value you're attempting to set the attribute to:

    class Payment < RubyFFDB::Document
      attribute :method,  :class => String, :validate => :valid_payment_methods
      attribute :amount, :class => Float
      
      def valid_payment_methods(method)
        ['visa', 'master card'].include? method
      end
    end
    
    payment = Payment.new
    payment.amount = 22.17
    payment.method = "amex"
    #  RubyFFDB::Exceptions::FailedValidation raised

The possibilities are endless, but this is it for now.

License
-------

RubyFFDB is distributed under the MIT License