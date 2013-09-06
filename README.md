RESTful Active Merchant
=======================

A RESTful, JSON wrapper around active_merchant, so non-ruby clients can consume this wonderful library.

Uses:
* Sinatra
* ActiveMerchant
* JSON
* Rack

API supports HTTP header based versioning (vs. url based) as per http://tomdmaguire.wordpress.com/2011/11/12/creating-a-restful-versioned-api-using-sinatra/ and http://barelyenough.org/blog/2008/05/versioning-rest-web-services/

API will include a UI for configuration, and options for data-based mapping to payment gateway to support Merchant of Record.

Server will be instrumented with statsd, and include webhook support for key operations.

Noodling on supporting payment queueing, as payment gateways can be slow.
