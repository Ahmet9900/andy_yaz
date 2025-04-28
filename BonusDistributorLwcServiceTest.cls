@IsTest
private class BonusDistributorLwcServiceTest {
    
    @IsTest
    static void testGetAccounts() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Birthdate = Date.newInstance(1990, 1, 1),
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Test that accounts with contacts having birthdates are returned
        Test.startTest();
        List<Account> accounts = BonusDistributorLwcService.getAccounts();
        Test.stopTest();
        
        System.assert(!accounts.isEmpty(), 'Should return accounts with contacts that have birthdates');
    }
    
    @IsTest
    static void testGetAccountsNoValidContacts() {
        // Create test data
        Account noBirthdateAccount = new Account(Name = 'No Birthdate Account');
        insert noBirthdateAccount;
        
        Contact noBirthdateContact = new Contact(
            FirstName = 'No',
            LastName = 'Birthdate',
            AccountId = noBirthdateAccount.Id
        );
        insert noBirthdateContact;
        
        // Test
        Test.startTest();
        List<Account> accounts = BonusDistributorLwcService.getAccounts();
        Test.stopTest();
        
        // Verify our test account with no birthdate isn't included
        Boolean found = false;
        for (Account acc : accounts) {
            if (acc.Id == noBirthdateAccount.Id) {
                found = true;
                break;
            }
        }
        System.assert(!found, 'Account with contacts without birthdates should not be returned');
    }
    
    @IsTest
    static void testDistributeBonusOldest() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            FirstName = 'Oldest',
            LastName = 'Contact',
            Birthdate = Date.newInstance(1975, 1, 1),
            AccountId = testAccount.Id
        ));
        testContacts.add(new Contact(
            FirstName = 'Younger',
            LastName = 'Contact',
            Birthdate = Date.newInstance(1990, 1, 1),
            AccountId = testAccount.Id
        ));
        insert testContacts;
        
        Decimal paymentAmount = 1000;
        
        // Test
        Test.startTest();
        List<Contact> updatedContacts = BonusDistributorLwcService.distributeBonus(
            paymentAmount, 
            testAccount.Id, 
            DistributePayment.DISTRIBUTION_TYPE_OLDEST
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, updatedContacts.size(), 'Should update only one contact for oldest distribution');
        
        Contact oldestContact = [SELECT LastName, Birthdate, PaymentAmount__c FROM Contact WHERE Id = :updatedContacts[0].Id];
        System.assertEquals('Contact', oldestContact.LastName, 'Should be the oldest contact');
        System.assertEquals(1975, oldestContact.Birthdate.year(), 'Should be born in 1975');
        System.assertEquals(paymentAmount, oldestContact.PaymentAmount__c, 'Full payment amount should go to oldest contact');
    }
    
    @IsTest
    static void testDistributeBonusYoungestAndAlphabeticallyFirst() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            FirstName = 'Beta',
            LastName = 'Anderson',
            Birthdate = Date.newInstance(1990, 1, 1),
            AccountId = testAccount.Id
        ));
        testContacts.add(new Contact(
            FirstName = 'Alpha',
            LastName = 'Zimmer',
            Birthdate = Date.newInstance(2000, 1, 1),
            AccountId = testAccount.Id
        ));
        insert testContacts;
        
        Decimal paymentAmount = 1000;
        
        // Test
        Test.startTest();
        List<Contact> updatedContacts = BonusDistributorLwcService.distributeBonus(
            paymentAmount, 
            testAccount.Id, 
            DistributePayment.DISTRIBUTION_TYPE_YOUNGEST_AND_ALPHABETICALLY_FIRST
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, updatedContacts.size(), 'Should update two contacts for this distribution type');
        
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : updatedContacts) {
            contactIds.add(c.Id);
        }
        List<Contact> updatedContactsFromDB = [SELECT LastName, Birthdate, PaymentAmount__c FROM Contact WHERE Id IN :contactIds];
        
        for (Contact c : updatedContactsFromDB) {
            System.assertEquals(500, c.PaymentAmount__c, 'Payment should be split equally between two contacts');
        }
        
        Boolean foundYoungest = false;
        Boolean foundAlphabeticallyFirst = false;
        for (Contact c : updatedContactsFromDB) {
            if (c.LastName == 'Zimmer' && c.Birthdate.year() == 2000) {
                foundYoungest = true;
            }
            if (c.LastName == 'Anderson') {
                foundAlphabeticallyFirst = true;
            }
        }
        System.assert(foundYoungest, 'Should include the youngest contact');
        System.assert(foundAlphabeticallyFirst, 'Should include the alphabetically first contact');
    }
    
    @IsTest
    static void testDistributeBonusEvenly() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            FirstName = 'First',
            LastName = 'Contact',
            Birthdate = Date.newInstance(1980, 1, 1),
            AccountId = testAccount.Id
        ));
        testContacts.add(new Contact(
            FirstName = 'Second',
            LastName = 'Contact',
            Birthdate = Date.newInstance(1990, 1, 1),
            AccountId = testAccount.Id
        ));
        testContacts.add(new Contact(
            FirstName = 'Third',
            LastName = 'Contact',
            Birthdate = Date.newInstance(2000, 1, 1),
            AccountId = testAccount.Id
        ));
        insert testContacts;
        
        Decimal paymentAmount = 100; // Using $100 to test penny distribution
        
        // Test
        Test.startTest();
        List<Contact> updatedContacts = BonusDistributorLwcService.distributeBonus(
            paymentAmount, 
            testAccount.Id, 
            DistributePayment.DISTRIBUTION_TYPE_EVENLY_DISTRIBUTED
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(3, updatedContacts.size(), 'Should update all contacts for even distribution');
        
        List<Contact> contactsFromDB = [SELECT PaymentAmount__c FROM Contact WHERE AccountId = :testAccount.Id];
        
        Decimal totalDistributed = 0;
        Integer contactsWith33 = 0;
        Integer contactsWith34 = 0;
        
        for (Contact c : contactsFromDB) {
            totalDistributed += c.PaymentAmount__c;
            if (c.PaymentAmount__c == 33.33) {
                contactsWith33++;
            } else if (c.PaymentAmount__c == 33.34) {
                contactsWith34++;
            }
        }
        
        System.assertEquals(100, totalDistributed, 'Total distributed should equal original payment amount');
        System.assertEquals(2, contactsWith33, 'Two contacts should have $33.33');
        System.assertEquals(1, contactsWith34, 'One contact should have $33.34');
    }
    
    @IsTest
    static void testDistributeBonusInvalidParameters() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Test negative payment amount
        Test.startTest();
        try {
            BonusDistributorLwcService.distributeBonus(-100, testAccount.Id, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
            System.assert(false, 'Should have thrown exception for negative payment amount');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid parameters'), 'Expected error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testDistributeBonusNoContactsWithBirthdates() {
        // Create test data
        Account noBirthdateAccount = new Account(Name = 'No Birthdate Account');
        insert noBirthdateAccount;
        
        Contact noBirthdateContact = new Contact(
            FirstName = 'No',
            LastName = 'Birthdate',
            AccountId = noBirthdateAccount.Id
        );
        insert noBirthdateContact;
        
        // Test
        Test.startTest();
        try {
            BonusDistributorLwcService.distributeBonus(100, noBirthdateAccount.Id, DistributePayment.DISTRIBUTION_TYPE_OLDEST);
            System.assert(false, 'Should have thrown exception for no contacts with birthdates');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No contacts found'), 'Expected error message');
        }
        Test.stopTest();
    }
}