public class OpportunityTriggerHandler extends TriggerHandler {
    public override void afterUpdate() {
        // Cast the new opportunities as List of Opps
        List<Opportunity> newOpps = (List<Opportunity>)Trigger.new;

        // Set to hold accountIds of updated Opportunities
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : newOpps) {
            if (o.AccountId != null) {
                accountIds.add(o.AccountId);
            }
        }

        // Initialise a map to store the count of Closed Won opportunities, defaulting to 0 for each accountId
        Map<Id, Integer> accountWinCounts = new Map<Id, Integer>();
        for (Id accountId : accountIds) {
            accountWinCounts.put(accountId, 0);
        }

        // Query to get the count of Closed Won opportunities grouped by AccountId
            List<AggregateResult> totalOpp = [
            SELECT COUNT(Id) totalWon, AccountId 
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND StageName = 'Closed Won'
            GROUP BY AccountId
        ];

        // Update the map with actual counts from the query result
        for (AggregateResult ar : totalOpp) {
            Id accountId = (Id) ar.get('AccountId');
            Integer totalWon = (Integer) ar.get('totalWon');
            accountWinCounts.put(accountId, totalWon);
        }

        // Prepare a list of Account updates based on the accountWinCounts map
        List<Account> accList = new List<Account>();
        for (Id accountId : accountWinCounts.keySet()) {
            Account acc = new Account(
                Id = accountId,
                Won_Opportunities_Count__c = accountWinCounts.get(accountId)
            );
            accList.add(acc);
        }

        // Update the Account records if there are any
        if (accList.size() > 0) {
            update accList;
        }
    }
}