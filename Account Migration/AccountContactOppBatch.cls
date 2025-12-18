global class AccountContactOppBatch implements Database.Batchable<SObject>, Database.Stateful {
    global List<Map<String,String>> accountRows, contactRows, opportunityRows, contactRoleRows;
    global Map<String, Id> accountMap = new Map<String, Id>();
    global Map<String, Id> contactMap = new Map<String, Id>();
    global List<Map<String,String>> accountErrors=new List<Map<String,String>>();
    global List<Map<String,String>> contactErrors=new List<Map<String,String>>();
    global List<Map<String,String>> opportunityErrors=new List<Map<String,String>>();
    global List<Map<String,String>> contactRoleErrors=new List<Map<String,String>>();
    global List<Map<String,String>> accountSuccess=new List<Map<String,String>>();
    global List<Map<String,String>> contactSuccess=new List<Map<String,String>>();
    global List<Map<String,String>> opportunitySuccess=new List<Map<String,String>>();
    global List<Map<String,String>> contactRoleSuccess=new List<Map<String,String>>();
    global Id jobId;

    global AccountContactOppBatch(List<Map<String,String>> a, List<Map<String,String>> c, List<Map<String,String>> o, List<Map<String,String>> cr, Id jobId){
        this.accountRows=a; this.contactRows=c; this.opportunityRows=o; this.contactRoleRows=cr; this.jobId=jobId;
    }

    global Iterable<SObject> start(Database.BatchableContext bc){ return new List<SObject>{new Account(Name='Dummy')}; }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        // 1️⃣ Accounts
        List<Account> accts = new List<Account>();
        for(Map<String,String> r:accountRows) accts.add(new Account(Name=r.get('Name')));
        Database.SaveResult[] results = Database.insert(accts,false);
        for(Integer i=0;i<results.size();i++){
            if(results[i].isSuccess()){ accountMap.put(accountRows[i].get('Id'), results[i].getId()); accountSuccess.add(accountRows[i]); }
            else accountErrors.add(addError(accountRows[i],results[i].getErrors()[0].getMessage()));
        }

        // 2️⃣ Contacts
        List<Contact> cons = new List<Contact>();
        for(Map<String,String> r:contactRows){
            if(accountMap.containsKey(r.get('Account_Name__c'))) cons.add(new Contact(FirstName=r.get('FirstName'), LastName=r.get('LastName'), AccountId=accountMap.get(r.get('Account_Name__c'))));
            else contactErrors.add(addError(r,'Account lookup failed'));
        }
        results=Database.insert(cons,false);
        for(Integer i=0;i<results.size();i++){
            if(results[i].isSuccess()){ contactMap.put(contactRows[i].get('Id'), results[i].getId()); contactSuccess.add(contactRows[i]); }
            else contactErrors.add(addError(contactRows[i],results[i].getErrors()[0].getMessage()));
        }

        // 3️⃣ Opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for(Map<String,String> r:opportunityRows){
            if(accountMap.containsKey(r.get('Account_Name__c'))) opps.add(new Opportunity(Name=r.get('Name'), AccountId=accountMap.get(r.get('Account_Name__c')), CloseDate=Date.today(), StageName='Prospecting'));
            else opportunityErrors.add(addError(r,'Account lookup failed'));
        }
        results=Database.insert(opps,false);
        for(Integer i=0;i<results.size();i++){
            if(results[i].isSuccess()) opportunitySuccess.add(opportunityRows[i]);
            else opportunityErrors.add(addError(opportunityRows[i],results[i].getErrors()[0].getMessage()));
        }

        // 4️⃣ Contact Roles
        List<Contact_Role__c> crs = new List<Contact_Role__c>();
        for(Map<String,String> r:contactRoleRows){
            if(contactMap.containsKey(r.get('Contact_Name__c')) && opportunityRows.size()>0){ 
                crs.add(new Contact_Role__c(Contact__c=contactMap.get(r.get('Contact_Name__c')), Opportunity__c=accountMap.get(r.get('Opportunity_Name__c')))); 
            } else contactRoleErrors.add(addError(r,'Contact or Opportunity lookup failed'));
        }
        results=Database.insert(crs,false);
        for(Integer i=0;i<results.size();i++){
            if(results[i].isSuccess()) contactRoleSuccess.add(contactRoleRows[i]);
            else contactRoleErrors.add(addError(contactRoleRows[i],results[i].getErrors()[0].getMessage()));
        }

        // Update job
        update new Migration_Job__c(
            Id=jobId,
            Accounts_Inserted__c=accountSuccess.size(),
            Contacts_Inserted__c=contactSuccess.size(),
            Opportunities_Inserted__c=opportunitySuccess.size(),
            Contact_Roles_Inserted__c=contactRoleSuccess.size()
        );
    }

    global void finish(Database.BatchableContext bc){
        Migration_Job__c job = new Migration_Job__c(Id=jobId);

        if(!accountErrors.isEmpty()) job.Accounts_Error_File_Id__c = saveCSV('Accounts_Errors.csv',toCSV(accountErrors));
        if(!contactErrors.isEmpty()) job.Contacts_Error_File_Id__c = saveCSV('Contacts_Errors.csv',toCSV(contactErrors));
        if(!opportunityErrors.isEmpty()) job.Opportunities_Error_File_Id__c = saveCSV('Opportunities_Errors.csv',toCSV(opportunityErrors));
        if(!contactRoleErrors.isEmpty()) job.Contact_Roles_Error_File_Id__c = saveCSV('Contact_Roles_Errors.csv',toCSV(contactRoleErrors));

        if(!accountSuccess.isEmpty()) job.Accounts_Success_File_Id__c = saveCSV('Accounts_Success.csv',toCSV(accountSuccess));
        if(!contactSuccess.isEmpty()) job.Contacts_Success_File_Id__c = saveCSV('Contacts_Success.csv',toCSV(contactSuccess));
        if(!opportunitySuccess.isEmpty()) job.Opportunities_Success_File_Id__c = saveCSV('Opportunities_Success.csv',toCSV(opportunitySuccess));
        if(!contactRoleSuccess.isEmpty()) job.Contact_Roles_Success_File_Id__c = saveCSV('Contact_Roles_Success.csv',toCSV(contactRoleSuccess));

        job.Status__c = (accountErrors.isEmpty() && contactErrors.isEmpty() && opportunityErrors.isEmpty() && contactRoleErrors.isEmpty()) ? 'Completed' : 'Completed With Errors';
        update job;
    }

    private Map<String,String> addError(Map<String,String> row,String msg){ Map<String,String> r = new Map<String,String>(row); r.put('Error_Message',msg); return r; }
    private String toCSV(List<Map<String,String>> rows){ 
        if(rows.isEmpty()) return '';
        Set<String> headers = rows[0].keySet(); 
        List<String> csv = new List<String>(); 
        csv.add(String.join(new List<String>(headers),',')); 
        for(Map<String,String> r:rows){ 
            List<String> line = new List<String>(); 
            for(String h:headers) line.add('"'+String.valueOf(r.get(h)).replace('"','""')+'"'); 
            csv.add(String.join(line,',')); 
        } 
        return String.join(csv,'\n'); 
    }
    private Id saveCSV(String name,String body){ 
        ContentVersion cv = new ContentVersion(Title=name, PathOnClient=name, VersionData=Blob.valueOf(body)); 
        insert cv; 
        return cv.Id; 
    }
}