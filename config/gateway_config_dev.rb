def get_gateway
    ActiveMerchant::Billing::Base.mode = :test
	gateway = ActiveMerchant::Billing::BraintreeGateway.new({
	  :login    => 'demo',
	  :password => 'password'
	})
end