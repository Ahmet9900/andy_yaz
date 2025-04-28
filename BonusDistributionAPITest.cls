@IsTest
private class BonusDistributionAPITest {

    @TestSetup
    static void setupData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alpha', LastName = 'Zane', AccountId = testAccount.Id, Birthdate = Date.newInstance(1980, 1, 1)),
            new Contact(FirstName = 'Beta', LastName = 'Young', AccountId = testAccount.Id, Birthdate = Date.newInstance(2000, 6, 15)),
            new Contact(FirstName = 'Gamma', LastName = 'Smith', AccountId = testAccount.Id, Birthdate = Date.newInstance(1995, 3, 10))
        };
        insert contacts;
    }

    @IsTest
    static void testSuccessfulBonusDistribution() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/distributeBonus';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => acct.Id,
            'paymentAmount' => 300,
            'distributionType' => 'evenly-distributed'
        }));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BonusDistributionAPI.distributeBonus();
        Test.stopTest();

        String responseBody = res.responseBody.toString();
        System.assertEquals(200, res.statusCode);
        System.assert(responseBody.contains('"success":true'));
        System.assert(responseBody.contains('Bonus distributed successfully.'));
        System.assert(responseBody.contains('updatedContacts'));
    }

    @IsTest
    static void testMissingParameters() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/distributeBonus';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => '001XXXXXXXXXXXX' // Missing paymentAmount and distributionType
        }));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BonusDistributionAPI.distributeBonus();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('Missing required parameters'));
    }

    @IsTest
    static void testInvalidDistributionType() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/distributeBonus';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => acct.Id,
            'paymentAmount' => 100,
            'distributionType' => 'invalid-distribution'
        }));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BonusDistributionAPI.distributeBonus();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('Invalid distribution type provided.'));
    }

    @IsTest
    static void testUnexpectedException() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/distributeBonus';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('not a valid json');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BonusDistributionAPI.distributeBonus();
        Test.stopTest();

        System.assertEquals(500, res.statusCode);
        System.assert(res.responseBody.toString().contains('An unexpected error occurred'));
    }
}