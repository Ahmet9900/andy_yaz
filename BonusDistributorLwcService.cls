public with sharing class BonusDistributorLwcService {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        try {
            return [
                SELECT Id, Name 
                FROM Account 
                WHERE Id IN (SELECT AccountId FROM Contact WHERE Birthdate != NULL) 
                ORDER BY Name
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving accounts: ' + e.getMessage());
        }
    }
     
    @AuraEnabled
    public static List<Contact> distributeBonus(Decimal paymentAmount, Id accountId, String distributionType) {
        try {
            if (paymentAmount <= 0 || accountId == null || String.isEmpty(distributionType)) {
                throw new AuraHandledException('Invalid parameters');
            }
            return DistributePayment.distribute(paymentAmount, accountId, distributionType);
        } catch (Exception e) {
            throw new AuraHandledException('Error distributing bonus: ' + e.getMessage());
        }
    }
}