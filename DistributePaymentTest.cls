@isTest
private class DistributePaymentTest {

   
    private static List<Contact> createTestContacts(Id accountId) {
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alice', LastName = 'Zimmerman', Birthdate = Date.newInstance(1980, 1, 1), AccountId = accountId),
            new Contact(FirstName = 'Bob', LastName = 'Anderson', Birthdate = Date.newInstance(1995, 6, 15), AccountId = accountId),
            new Contact(FirstName = 'Charlie', LastName = 'Brown', Birthdate = Date.newInstance(2000, 12, 31), AccountId = accountId)
        };
        insert contacts;
        return contacts;
    }

   @isTest
static void testDistributeToOldest() {
    Account acct = new Account(Name = 'Test Account - Oldest');
    insert acct;

    List<Contact> contacts = createTestContacts(acct.Id);

    Test.startTest();
    DistributePayment.distribute(300.00, acct.Id, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
    Test.stopTest();

    // Query all contacts again to get updated values
    List<Contact> updatedContacts = [
        SELECT FirstName, LastName, PaymentAmount__c, Birthdate
        FROM Contact
        WHERE AccountId = :acct.Id and Birthdate!=null
        ORDER BY Birthdate ASC
    ];

    System.assertEquals(300.00, updatedContacts[0].PaymentAmount__c, 'Oldest contact should receive full bonus');
    System.assertEquals(null, updatedContacts[1].PaymentAmount__c, 'Younger contacts should not receive bonus');
    System.assertEquals(null, updatedContacts[2].PaymentAmount__c, 'Younger contacts should not receive bonus');
}

    @isTest
static void testDistributeToYoungestAndAlphabeticallyFirst() {
    Account acct = new Account(Name = 'Test Account - Youngest and Alpha');
    insert acct;

    List<Contact> contacts = createTestContacts(acct.Id);

    Test.startTest();
    DistributePayment.distribute(500.00, acct.Id, DistributePayment.DISTRIBUTION_TYPE_YOUNGEST_AND_ALPHABETICALLY_FIRST);
    Test.stopTest();

    // Query all contacts again to get updated values
    List<Contact> updatedContacts = [
        SELECT FirstName, LastName, PaymentAmount__c
        FROM Contact
        WHERE AccountId = :acct.Id
    ];

    Map<String, Decimal> expectedAmounts = new Map<String, Decimal>{
        'Anderson'   => 250.00, // Alphabetically first
        'Brown'      => 250.00, // Youngest
        'Zimmerman'  => null
    };

    for (Contact c : updatedContacts) {
        System.assertEquals(
            expectedAmounts.get(c.LastName),
            c.PaymentAmount__c,
            'Check correct distribution for ' + c.LastName
        );
    }
}

    @isTest
    static void testDistributeEvenly() {
        Account acct = new Account(Name = 'Test Account - Even');
        insert acct;

        List<Contact> contacts = createTestContacts(acct.Id);

        Test.startTest();
        List<Contact> updatedContacts = DistributePayment.distribute(150.00, acct.Id, DistributePayment.DISTRIBUTION_TYPE_EVENLY_DISTRIBUTED);
        Test.stopTest();

        Decimal expectedAmount = 50.00;
        for (Contact c : updatedContacts) {
            System.assertEquals(expectedAmount, c.PaymentAmount__c.setScale(2), 'Each contact should get equal share');
        }
    }

    @isTest
    static void testInvalidDistributionType() {
        Account acct = new Account(Name = 'Test Account - Invalid Type');
        insert acct;
        createTestContacts(acct.Id);

        Test.startTest();
        try {
            DistributePayment.distribute(100.00, acct.Id, 'invalid-type');
            System.assert(false, 'Expected CustomException for invalid distribution type');
        } catch (DistributePayment.CustomException e) {
            System.assert(e.getMessage().contains('Invalid distribution type'), 'Should throw correct custom exception');
        }
        Test.stopTest();
    }

    @isTest
    static void testMissingContacts() {
        Account acct = new Account(Name = 'Empty Account');
        insert acct;

        Test.startTest();
        try {
            DistributePayment.distribute(100.00, acct.Id, DistributePayment.DISTRIBUTION_TYPE_EVENLY_DISTRIBUTED);
            System.assert(false, 'Expected CustomException for no contacts');
        } catch (DistributePayment.CustomException e) {
            System.assert(e.getMessage().contains('No contacts found'), 'Should throw correct custom exception');
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidParameters() {
        Test.startTest();
        try {
            DistributePayment.distribute(null, null, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
            System.assert(false, 'Expected CustomException for invalid parameters');
        } catch (DistributePayment.CustomException e) {
            System.assert(e.getMessage().contains('must be valid'), 'Should throw correct custom exception');
        }
        Test.stopTest();
    }
}
