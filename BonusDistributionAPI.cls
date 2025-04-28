@RestResource(urlMapping='/distributeBonus')
global with sharing class BonusDistributionAPI {

    @HttpPost
    global static void distributeBonus() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
           
            String requestBody = req.requestBody.toString();
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            
            if (!body.containsKey('accountId') || !body.containsKey('paymentAmount') || !body.containsKey('distributionType')) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(false, 'Missing required parameters: accountId, paymentAmount, distributionType', null)));
                return;
            }

            Id accountId = (Id) body.get('accountId');
            Decimal paymentAmount = Decimal.valueOf(String.valueOf(body.get('paymentAmount')));
            String distributionType = (String) body.get('distributionType');

            // Call distribution logic
            List<Contact> updatedContacts = DistributePayment.distribute(paymentAmount, accountId, distributionType);

            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(true, 'Bonus distributed successfully.', updatedContacts)));
        } catch (DistributePayment.CustomException e) {
            res.statusCode = 400; // Custom business rule violations
            res.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(false, e.getMessage(), null)));
        } catch (Exception e) {
            res.statusCode = 500; // System/unexpected errors
            res.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(false, 'An unexpected error occurred: ' + e.getMessage(), null)));
        }
    }

    
    global class ResponseWrapper {
        public Boolean success { get; set; }
        public String message { get; set; }
        public List<Contact> updatedContacts { get; set; }

        public ResponseWrapper(Boolean success, String message, List<Contact> updatedContacts) {
            this.success = success;
            this.message = message;
            this.updatedContacts = updatedContacts;
        }
    }
}
