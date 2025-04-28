@IsTest
private class BonusDistributorLwcServiceTest {
    private static Account testAccount;
    private static List<Contact> testContacts;
    
    private static void setupData() {
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Date today = Date.today();
        testContacts = new List<Contact>{
            new Contact(FirstName = 'Oldest', LastName = 'Zebra', Birthdate = today.addYears(-50), AccountId = testAccount.Id),
            new Contact(FirstName = 'Middle', LastName = 'Alpha', Birthdate = today.addYears(-30), AccountId = testAccount.Id),
            new Contact(FirstName = 'Youngest', LastName = 'Beta', Birthdate = today.addYears(-20), AccountId = testAccount.Id)
        };
        insert testContacts;
    }
    
    @IsTest
    static void getAccounts_ReturnsValidAccounts() {
        setupData();
        Test.startTest();
        List<Account> accounts = BonusDistributorLwcService.getAccounts();
        Test.stopTest();
        System.assertEquals(1, accounts.size(), 'Should return account with contacts');
        System.assertEquals(testAccount.Id, accounts[0].Id);
    }
    
    @IsTest
    static void distributeBonus_OldestDistribution() {
        setupData();
        Test.startTest();
        List<Contact> result = BonusDistributorLwcService.distributeBonus(
            1000, testAccount.Id, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Should update oldest contact');
        System.assertEquals(1000, [SELECT PaymentAmount__c FROM Contact WHERE Id = :result[0].Id].PaymentAmount__c);
    }
    
    @IsTest
    static void distributeBonus_YoungestAndAlphaDistribution() {
        setupData();
        Test.startTest();
        List<Contact> result = BonusDistributorLwcService.distributeBonus(
            1000, testAccount.Id, DistributePayment.DISTRIBUTION_TYPE_YOUNGEST_AND_ALPHABETICALLY_FIRST);
        Test.stopTest();
        System.assertEquals(2, result.size(), 'Should update two contacts');
        System.assertEquals(500, [SELECT PaymentAmount__c FROM Contact WHERE LastName = 'Alpha'].PaymentAmount__c);
        System.assertEquals(500, [SELECT PaymentAmount__c FROM Contact WHERE LastName = 'Beta'].PaymentAmount__c);
    }
    
    @IsTest
    static void distributeBonus_EvenDistribution() {
        setupData();
        Test.startTest();
        List<Contact> result = BonusDistributorLwcService.distributeBonus(
            1000, testAccount.Id, DistributePayment.DISTRIBUTION_TYPE_EVENLY_DISTRIBUTED);
        Test.stopTest();
        System.assertEquals(3, result.size(), 'Should update all contacts');
        Decimal total = 0;
        for (Contact c : [SELECT PaymentAmount__c FROM Contact]) {
            total += c.PaymentAmount__c;
        }
        System.assertEquals(1000, total, 'Total should equal original amount');
    }
    
    @IsTest
    static void distributeBonus_ThrowsErrorForInvalidInputs() {
        setupData();
        Test.startTest();
        
        try {
            BonusDistributorLwcService.distributeBonus(1000, null, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('valid'));
        }
        
        
        try {
            BonusDistributorLwcService.distributeBonus(-100, testAccount.Id, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('valid'));
        }
        
       
        try {
            BonusDistributorLwcService.distributeBonus(1000, testAccount.Id, 'invalid');
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid'));
        }
        Test.stopTest();
    }
}