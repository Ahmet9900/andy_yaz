public with sharing class BonusDistributorLwcService {
    
   @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
    return [
        SELECT Id, Name 
        FROM Account where Id IN (select AccountId from contact where birthdate!=null) 
        ORDER BY Name
        LIMIT 100
        ];
    }
    
    @AuraEnabled
    public static List<Contact> distributeBonus(Decimal paymentAmount, Id accountId, String distributionType) {
        return DistributePayment.distribute(paymentAmount, accountId, distributionType);
    }
}