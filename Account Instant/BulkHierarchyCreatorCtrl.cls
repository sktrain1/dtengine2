public with sharing class BulkHierarchyCreatorCtrl {

    public class CreatedWrapper {
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String opportunityId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String contactId;
        @AuraEnabled public String contactName;
    }

    @AuraEnabled
    public static List<CreatedWrapper> createHierarchy(
        Id recordTypeId,
        String stageName,
        Integer count,
        String prefix
    ) {
    //     if (count == null || count <= 0) return new List<CreatedWrapper>();
    //     if (String.isBlank(prefix)) prefix = 'ACC';

    //     List<Account> accounts = new List<Account>();
    //     for (Integer i = 0; i < count; i++) {
    //         accounts.add(new Account(
    //             Name = prefix + randomString(7),
    //             RecordTypeId = recordTypeId
    //         ));
    //     }
    //     insert accounts;

    //     List<Opportunity> opps = new List<Opportunity>();
    //     List<Contact> contacts = new List<Contact>();

    //     for (Account acc : accounts) {
    //         opps.add(new Opportunity(
    //             Name = acc.Name + ' Opp',
    //             AccountId = acc.Id,
    //             StageName = stageName,
    //             CloseDate = Date.today().addDays(30),
    //             RecordTypeId = recordTypeId
    //         ));

    //         contacts.add(new Contact(
    //             LastName = acc.Name + ' Contact',
    //             AccountId = acc.Id,
    //             RecordTypeId = recordTypeId
    //         ));
    //     }

    //     insert opps;
    //     insert contacts;

    //     // Build response for download
    //     List<CreatedWrapper> response = new List<CreatedWrapper>();
    //     for (Integer i = 0; i < accounts.size(); i++) {
    //         CreatedWrapper w = new CreatedWrapper();
    //         w.accountId = accounts[i].Id;
    //         w.accountName = accounts[i].Name;
    //         w.opportunityId = opps[i].Id;
    //         w.opportunityName = opps[i].Name;
    //         w.contactId = contacts[i].Id;
    //         w.contactName = contacts[i].LastName;
    //         response.add(w);
    //     }
    //     return response;

        return new List<CreatedWrapper>();
    }

    private static String randomString(Integer len) {
        // String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        // String result = '';
        // for (Integer i = 0; i < len; i++) {
        //     Integer idx = Math.mod(Crypto.getRandomInteger(), chars.length());
        //     result += chars.substring(idx, idx + 1);
        // }
        // return result;

        return 'abc';
    }

    // ---------------- Picklists ----------------

    @AuraEnabled(cacheable=true)
    public static List<RecordType> getAccountRecordTypes() {
        return [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getOpportunityStages() {
        // List<String> stages = new List<String>();
        // for (Schema.PicklistEntry p :
        //     Schema.SObjectType.Opportunity.fields.StageName
        //         .getDescribe().getPicklistValues()
        // ) {
        //     stages.add(p.getLabel());
        // }
        // return stages;

        return null;
    }
}