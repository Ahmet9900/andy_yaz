public with sharing class DistributePayment {

    public static final String DISTRIBUTION_TYPE_OLDEST = 'oldest';
    public static final String DISTRIBUTION_TYPE_YOUNGEST_AND_ALPHABETICALLY_FIRST = 'youngest-and-alphabetically-first';
    public static final String DISTRIBUTION_TYPE_EVENLY_DISTRIBUTED = 'evenly-distributed';

    public static List<Contact> distribute(Decimal paymentAmount, Id acctId, String distributionType) {
        if (acctId == null || paymentAmount == null || paymentAmount <= 0) {
            throw new CustomException('Account Id and Payment Amount must be valid and non-null.');
        }

        List<Contact> receivingContactsByBirthdate = getContactsSortedByBirthdate(acctId);

        if (receivingContactsByBirthdate.isEmpty()) {
            throw new CustomException('No contacts found in Account to receive distribution.');
        }

        // Return only updated contacts
        if (distributionType == DISTRIBUTION_TYPE_OLDEST) {
            return distributeToOldest(paymentAmount, receivingContactsByBirthdate);
        } else if (distributionType == DISTRIBUTION_TYPE_YOUNGEST_AND_ALPHABETICALLY_FIRST) {
            return distributeToYoungestAndAlphabeticallyFirst(paymentAmount, acctId, receivingContactsByBirthdate);
        } else if (distributionType == DISTRIBUTION_TYPE_EVENLY_DISTRIBUTED) {
            return distributeEvenly(paymentAmount, receivingContactsByBirthdate);
        } else {
            throw new CustomException('Invalid distribution type provided.');
        }
    }

    private static List<Contact> getContactsSortedByBirthdate(Id acctId) {
        return [
            SELECT Id, Name, LastName, Birthdate, PaymentAmount__c
            FROM Contact
            WHERE AccountId = :acctId and Birthdate!=null
            ORDER BY Birthdate ASC
        ];
    }

    private static List<Contact> distributeToOldest(Decimal paymentAmount, List<Contact> contacts) {
        Contact oldestContact = contacts[0]; 
        oldestContact.PaymentAmount__c = paymentAmount;
        update oldestContact;
        return new List<Contact>{oldestContact};
    }

    private static List<Contact> distributeToYoungestAndAlphabeticallyFirst(Decimal paymentAmount, Id acctId, List<Contact> contacts) {
        List<Contact> receivingContactsByLastName = [
            SELECT Id, Name, LastName, Birthdate, PaymentAmount__c
            FROM Contact
            WHERE AccountId = :acctId
            ORDER BY LastName ASC
        ];

        Contact alphabeticallyFirstContact = receivingContactsByLastName[0]; 
        Contact youngestContact = contacts[contacts.size() - 1]; 

        Decimal halfBonus = paymentAmount / 2;
        alphabeticallyFirstContact.PaymentAmount__c = halfBonus;
        youngestContact.PaymentAmount__c = halfBonus;

        update new List<Contact>{alphabeticallyFirstContact, youngestContact};
        return new List<Contact>{alphabeticallyFirstContact, youngestContact};
    }

   private static List<Contact> distributeEvenly(Decimal paymentAmount, List<Contact> contacts) {
    Integer count = contacts.size();
    Decimal baseAmount = (paymentAmount / count).setScale(2, RoundingMode.DOWN);
    
    // Calculate the total of the base amounts
    Decimal totalBase = baseAmount * count;
    
    // Find the remaining amount (difference to fix)
    Decimal remainder = (paymentAmount - totalBase).setScale(2, RoundingMode.HALF_UP);

    Integer cents = (remainder * 100).intValue(); // Convert remainder to cents

    // Now distribute the cents one-by-one
    for (Integer i = 0; i < contacts.size(); i++) {
        if (i < cents) {
            contacts[i].PaymentAmount__c = baseAmount + 0.01;
        } else {
            contacts[i].PaymentAmount__c = baseAmount;
        }
    }

    update contacts;
    return contacts;
}
    public class CustomException extends Exception {}
}