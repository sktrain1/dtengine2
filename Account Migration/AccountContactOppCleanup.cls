public class AccountContactOppCleanup {

    public static void eraseAll() {
        //deleteInBatches([SELECT Id FROM Contact_Role__c]);
        deleteInBatches([SELECT Id FROM Opportunity]);
        deleteInBatches([SELECT Id FROM Contact]);
        deleteInBatches([SELECT Id FROM Account]);
        deleteInBatches([SELECT Id FROM Migration_Job__c]);
    }

    private static void deleteInBatches(List<SObject> records) {
        if(records.isEmpty()) return;

        Integer batchSize = 200;
        List<SObject> tempBatch = new List<SObject>();

        for(Integer i = 0; i < records.size(); i++) {
            tempBatch.add(records[i]);
            // When batch is full or last record, delete
            if(tempBatch.size() == batchSize || i == records.size() - 1) {
                delete tempBatch;
                tempBatch.clear();
            }
        }
    }
}