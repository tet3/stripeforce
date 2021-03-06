global class StripeCharge {
	private static final String SERVICE_URL = 'https://api.stripe.com/v1/charges';

	global Integer amount;
	global Integer created;
	global String stripeCurrency;
	global String customer_id;
	global StripeCustomer customer;
	global String description;
	global Boolean disputed;
	global Integer fee;
	global String id;
	global Boolean livemode;
	global String stripeObject;
	global Boolean paid;
	global Boolean refunded;
	global Integer amount_refunded;
	global StripeCard card;
	global List<Fee_details> fee_details;
	global StripeError error;
	global String invoice_id;
	global StripeInvoice invoice;
	global String failure_message;
	global Map<String, String> metadata;

	// This has changed in the 2013-02-13 API
	// https://stripe.com/docs/upgrades#2013-02-13
	// And more recently on 2013-08-13
	// https://stripe.com/docs/upgrades#2013-08-13
	global class Fee_details {
		global String stripeType;
		global String description;
		global Object application;
		global Integer amount;
		global String stripeCurrency;
	}

	global static StripeCharge getCharge(String chargeId) {
		return StripeCharge.getCharge(chargeId, false);
	}
	
	global static StripeCharge getCharge(String chargeId, Boolean expandInvoice) {
		HttpRequest http = new HttpRequest();
		String endPoint = SERVICE_URL+'/'+chargeId;
		if (expandInvoice) endPoint += '?expand[]=invoice';
		System.debug(System.LoggingLevel.INFO, '\n**** StripeCharge.getCharge endpoint: '+endPoint); 
		http.setEndpoint(endPoint);
		http.setMethod('GET');
		Blob headerValue = Blob.valueOf(StripeAPI.ApiKey + ':');
		String authorizationHeader = 'BASIC ' +
		EncodingUtil.base64Encode(headerValue);
		http.setHeader('Authorization', authorizationHeader);
		
		String response;
		Integer statusCode;
		Http con = new Http();
		HttpResponse hs = new HttpResponse();
		
		if (!Test.isRunningTest()) {
			try {
				hs = con.send(http);
			} catch (CalloutException e) {
				return null;
			}
		} else {
			hs.setBody(StripeChargeTests.testData_getCharge);
			hs.setStatusCode(200);
		}

		system.debug('#### '+ hs.getBody());
		
		response = hs.getBody();
		statusCode = hs.getStatusCode();
		
		try {
			StripeCharge o = StripeCharge.parse(response);
			return o;
		} catch (System.JSONException e) {
			System.debug(System.LoggingLevel.INFO, '\n**** '+e); 
			return null;
		}
	}
	
	global static StripeCharge create(String customerId, Decimal amount) {
		return create(customerId, amount, new Map<String, String>(), new Map<String, String>());
	}
	
	// DEPRECATED
	global static StripeCharge create(String customerId, Decimal amount, String description) {
		Map<String, String> properties = new Map<String, String>{
			'description' => description
		};
		
		return create(customerId, amount, properties, null);
	}

	// DEPRECATED
	global static StripeCharge create(String customerId, Decimal amount, String description, Map<String, String> metadata) {
		Map<String, String> properties = new Map<String, String>{
			'description' => description
		};
		
		return create(customerId, amount, properties, metadata);
	}

	global static StripeCharge create(String customerId, Decimal amount, Map<String, String> properties, Map<String, String> metadata) {
		HttpRequest http = new HttpRequest();
		http.setEndpoint(SERVICE_URL);
		http.setMethod('POST');
		Blob headerValue = Blob.valueOf(StripeAPI.ApiKey + ':');
		String authorizationHeader = 'BASIC ' +
		EncodingUtil.base64Encode(headerValue);
		http.setHeader('Authorization', authorizationHeader);
		
		Integer amount_int = Math.round(amount * 100);//.intValue();
		Map<String, String> payload = new Map<String, String>{
			'customer' => customerId,
			'amount' => String.valueOf(amount_int)
		};

		// set the default currency to USD if it's not specified
		if (properties == null || properties.containsKey('usd') == false) {
			payload.put('currency', 'usd');
		}

		if (properties != null) {
			for (String key : properties.keySet()) {
				if (properties.get(key) != null) {
					payload.put(key, properties.get(key));
				}
			}
		}

		if (metadata != null) {
			for (String key : metadata.keySet()) {
				if (metadata.get(key) != null) {
					payload.put('metadata['+key+']', metadata.get(key));
				}
			}
		}

		http.setBody(StripeUtil.urlify(payload));
		System.debug(System.LoggingLevel.INFO, '\n**** REQUEST BODY:\n'+http.getBody()); 	
		
		String response;
		Integer statusCode;
		Http con = new Http();
		HttpResponse hs = new HttpResponse();
		
		if (!Test.isRunningTest()) {
			try {
				hs = con.send(http);
			} catch (CalloutException e) {
				return null;
			}
		} else {
			hs.setBody(StripeChargeTests.testData_createCharge);
			hs.setStatusCode(200);
		}

		system.debug('#### '+ hs.getBody());
		
		response = hs.getBody();
		statusCode = hs.getStatusCode();
		system.debug('$$statusCode = '+hs.getStatusCode());
		
		try {
			StripeCharge o = StripeCharge.parse(response);
			System.debug(System.LoggingLevel.INFO, '\n**** StripeCharge object: '+o); 
			return o;
		} catch (System.JSONException e) {
			System.debug(System.LoggingLevel.INFO, '\n**** JSONException: '+e); 
			return null;
		}
	}

	public static StripeCharge parse(String json) {
		// rough string replacement to simplify json parsing and avoid Apex reserved words
		json = StripeUtil.cleanJson(json);

		return (StripeCharge) System.JSON.deserialize(json, StripeCharge.class);
	}
}