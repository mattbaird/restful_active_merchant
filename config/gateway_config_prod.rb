def get_gateway
    ActiveMerchant::Billing::Base.mode = :test
    gateway = ActiveMerchant::Billing::BraintreeGateway.new({
      :merchant_id => 'your merchant id',
      :public_key  => 'your public key',
      :private_key => 'your private key'    
    })
end