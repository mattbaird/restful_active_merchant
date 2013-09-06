RESTful Active Merchant
=======================

A RESTful, JSON wrapper around active_merchant, so non-ruby clients can consume this wonderful library.

Uses:
* Sinatra
* ActiveMerchant
* JSON
* Rack

API supports HTTP header based versioning (vs. url based) as per http://tomdmaguire.wordpress.com/2011/11/12/creating-a-restful-versioned-api-using-sinatra/ and http://barelyenough.org/blog/2008/05/versioning-rest-web-services/

Versioning
==========
```
===>
GET /creditcard/1 HTTP/1.1
Accept: application/vnd.mattbaird.activemerchant+json
<===
HTTP/1.1 200 OK
Content-Type: application/vnd.mattbaird.activemerchant+json

{"number":"4111111111111111","month":"8","year":"2009","first_name":"Tobias","last_name":"Luetke","verification_value":"123"}
```
Of course, there is no way to request a credit card, this is just an example.

Plans
=====

API will include a UI for configuration, and options for data-based mapping to payment gateway to support Merchant of Record.

Server will be instrumented with statsd, and include webhook support for key operations.

Noodling on supporting payment queueing, as payment gateways can be slow.

API inspired by http://guides.spreecommerce.com/api/payments.html
