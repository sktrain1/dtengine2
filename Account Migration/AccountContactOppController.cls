public with sharing class AccountContactOppController {

    @AuraEnabled(cacheable=false)
    public static Id startMigration(List<Map<String,String>> accounts, List<Map<String,String>> contacts, List<Map<String,String>> opportunities, List<Map<String,String>> contactRoles){
        // Migration_Job__c job = new Migration_Job__c(Status__c='Processing');
        // insert job;
        // Database.executeBatch(new AccountContactOppBatch(accounts, contacts, opportunities, contactRoles, job.Id), 200);
        // return job.Id;

        return null;
    }

    @AuraEnabled(cacheable=false)
    public static Migration_Job__c getJobStatus(Id jobId){
        // return [SELECT Id, Status__c,
        //     Accounts_Inserted__c, Contacts_Inserted__c, Opportunities_Inserted__c, Contact_Roles_Inserted__c,
        //     Accounts_Error_File_Id__c, Contacts_Error_File_Id__c, Opportunities_Error_File_Id__c, Contact_Roles_Error_File_Id__c,
        //     Accounts_Success_File_Id__c, Contacts_Success_File_Id__c, Opportunities_Success_File_Id__c, Contact_Roles_Success_File_Id__c
        //     FROM Migration_Job__c WHERE Id=:jobId];

        return null;
    }

    @AuraEnabled
    public static void cleanAllData(){ AccountContactOppCleanup.eraseAll(); }
}