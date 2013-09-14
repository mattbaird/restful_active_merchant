require 'rack/conneg'
require 'rack/replace_http_accept'
require 'rack/rest_api_versioning'
require 'active_merchant'
require 'json'
require 'sinatra'
require 'yaml'

#TODO
# externalize gateway configuration
# test mode, tests + failure testing mode

APP_CONFIG = YAML.load_file("config/config.yaml")

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

	def respond data, version, http_response=200
      respond_to do |wants|
         wants.json  {
            # Set Content-Type header accordingly
            content_type "application/vnd.mattbaird.activemerchant-v#{version}+json"
            status http_response
            data.to_json
         }
         wants.xml   {
            content_type "application/vnd.mattbaird.activemerchant-v#{version}+xml"
            status http_response
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

  require_relative "config/gateway_config_#{APP_CONFIG['environment']}"

  def number
    "#{Time.now.to_i}-#{rand(1_000_000)}"
  end

  # here is where the actual methods live
  get '/' do
    '{"greeting":"hello world"}'
  end

  # Payment Index and Search
  get '/api/orders/:order_id/payments?:page_number?:per_page?' do
    order_id = params[:order_id]
    page_number = params[:page]
    per_page = params[:per_page]
    version = env['api_version']
    gw = get_gateway()
    hash = Hash["method" => "index","order_id" => order_id, "page_number" => page_number, "per_page" => per_page]
    respond hash, version
  end

  #New Payment - gets payment methods
  get '/api/orders/:order_id/payments/new' do
    order_id = params[:order_id]
    version = env['api_version']
    hash = Hash["method" => "new","order_id" => order_id]
    respond hash, version
  end

  #create new payment
  post '/api/orders/:order_id/payments?:payment_method_id?:amount?' do
    order_id = params[:order_id]
    payment_method_id = params[:payment_method_id]
    amount = params[:amount]
    version = env['api_version']
    hash = Hash["method" => "create","order_id" => order_id, "payment_method_id" => payment_method_id, "amount" => amount]
    respond hash, version
  end

  #To get information for a particular payment, make a request like this
  get '/api/orders/:order_id/payments/:payment_id' do
    payment_id = params[:payment_id]
    order_id = params[:order_id]
    version = env['api_version']
    gw = get_gateway()

    hash = Hash["method" => "info","order_id" => order_id, "payment_id" => payment_id]
    respond hash, version
  end

  #To authorize a payment, make a request like this
  put '/api/orders/:order_id/payments/:payment_id/authorize' do
    payment_id = params[:payment_id]
    order_id = params[:order_id]
    version = env['api_version']
    gw = get_gateway()
    gw.authorize(amount, credit_card, options)
    hash = Hash["method" => "authorize","order_id" => order_id, "payment_id" => payment_id]
    respond hash, version
  end

  #To capture a payment, make a request like this
  put '/api/orders/:order_id/payments/:payment_id/capture' do
    payment_id = params[:payment_id]
    order_id = params[:order_id]
    version = env['api_version']
    hash = Hash["method" => "capture","order_id" => order_id, "payment_id" => payment_id]
    respond hash, version
  end

  #Purchasing a payment is typically done only if you are not authorizing payments before-hand.
  # If you are authorizing payments, then use the authorize and capture endpoints instead.
  #To make a purchase with a payment, make a request like this
  put '/api/orders/:order_id/payments/:payment_id/purchase' do
    payment_id = params[:payment_id]
    order_id = params[:order_id]
    version = env['api_version']
    cc_from_body = request.body.read
    gw = get_gateway()
    # pull credit card info from body
    hashed_cc = JSON.parse(cc_from_body)
    # TODO: error checking on cc_from_body
    credit_card = ActiveMerchant::Billing::CreditCard.new({
    :first_name => hashed_cc["first_name"],
    :last_name => hashed_cc["last_name"],
    :number => hashed_cc["number"],
    :month => hashed_cc["month"],
    :year => hashed_cc["year"],
    :verification_value => hashed_cc["verification_value"]
    })

    # TODO: add support for additional data such as street_match and postal_match
    # order_id, ip, customer, invoice, merchant, description, email, currency, billing_address, shipping_address
    if credit_card.valid?
      response = gw.purchase(100, credit_card)
      print "(TEST) " if response.test?
      if response.success?
        hash = Hash["order_id" => order_id, "payment_id" => payment_id, "amount" => 100, "avs_result" =>  response.avs_result,
                   "response_code" => response.authorization, "message" => response.message,  "test" => response.test]
        respond hash, version
      else
        hash = Hash["error" => "There was a problem with the payment gateway: [#{response.message}]"]
        respond hash, version, 422
      end
    else
        hash = Hash["error" => "The credit card is invalid."]
        respond hash, version, 422
    end
  end


  #To void a payment, make a request like this
  put '/api/orders/:order_id/payments/:payment_id/void' do
    payment_id = params[:payment_id]
    order_id = params[:order_id]
    version = env['api_version']
    gw = get_gateway()
    # TODO get authorization code for order_id/payment_id

    authorization = ""
    response = gw.void(authorization)
    if response.success?
      hash = Hash["order_id" => order_id, "payment_id" => payment_id, "amount" => response.amount, "avs_result" =>  response.avs_result,
                 "response_code" => response.authorization, "message" => response.message,  "test" => response.test]
      respond hash, version
    else
      hash = Hash["error" => "There was a problem with the payment gateway: [#{response.message}]"]
      respond hash, version, 422
    end
    hash = Hash["method" => "void","order_id" => order_id, "payment_id" => payment_id]
    respond hash, version
  end

  #To credit a payment, make a request like this
  put '/api/orders/:order_id/payments/:payment_id/credit?:amount?' do
    payment_id = params[:payment_id]
    order_id = params[:order_id]
    amount = params[:amount]
    version = env['api_version']
    hash = Hash["method" => "credit", "order_id" => order_id, "payment_id" => payment_id, "amount" => amount]
    respond hash, version
  end

end

ActiveMerchantApi.run!
