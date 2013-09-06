require 'rack/conneg'
require 'rack/replace_http_accept'
require 'rack/rest_api_versioning'
require 'active_merchant'
require 'json'
require 'sinatra'

class JsonCreditCard < ActiveMerchant::Billing::CreditCard
#  def to_json(options={})
 #    {
 #      :column_name => "discobiscuit",
 #      :some_other_name => "blarg"
 #    }.to_json
 #  end
   def to_hash
    hash = {}
    instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    hash
  end
end

class ActiveMerchantApi < Sinatra::Base

	#bind to all interfaces so vagrant port forwarding works
	set :bind, '0.0.0.0'

   # Set default API version
   use Rack::RestApiVersioning, :default_version => '1'

   # Create custom vendor mime type mappings
   use Rack::ReplaceHttpAccept, /application\/vnd\.mattbaird\.activemerchant-v[0-9]+\+json/ => 'application/json',
   /application\/vnd\.mattbaird\.activemerchant-v[0-9]+\+xml/  => 'application/xml'

   # Initalise Conneg
   use(Rack::Conneg) { |conneg|
      conneg.set :accept_all_extensions, false
      conneg.provide([:json, :xml])
   }


	get '/' do
		'{"greeting":"hello world"}'
	end
	get '/hi' do
		'Hello World!'
	end

	get '/retail/products' do
	  version = env['api_version']
	  respond get_product_data(version), version
	end

	def get_product_data version
      # Send requests to the gateway's test servers
      ActiveMerchant::Billing::Base.mode = :test

      # Create a new credit card object
      credit_card = JsonCreditCard.new(
        :number     => '4111111111111111',
        :month      => '8',
        :year       => '2009',
        :first_name => 'Tobias',
        :last_name  => 'Luetke',
        :verification_value  => '123'
      )
      credit_card.to_hash
	end

	def respond data, version
      respond_to do |wants|
         wants.json  {
            # Set Content-Type header accordingly
            content_type "application/vnd.mattbaird.activemerchant-v#{version}+json"
            data.to_json
         }
         wants.xml   {
            content_type "application/vnd.mattbaird.activemerchant-v#{version}+xml"
            data.to_xml
         }
         wants.other {
            content_type 'text/plain'
            error 406, "Not Acceptable"
         }
      end
   end

   before do
      if negotiated?
         # Important: resource cacheable based on Content-Type
         headers "Vary" => "Content-Type"
      end
   end
end

ActiveMerchantApi.run!
