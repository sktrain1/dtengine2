import { LightningElement, track } from 'lwc';
import startMigration from '@salesforce/apex/AccountContactOppController.startMigration';
import getJobStatus from '@salesforce/apex/AccountContactOppController.getJobStatus';
import cleanAllData from '@salesforce/apex/AccountContactOppController.cleanAllData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountContactOppLoader extends LightningElement {
    @track accountsData = [];
    @track contactsData = [];
    @track opportunitiesData = [];
    @track contactRolesData = [];

    @track uploadedAccounts = null;
    @track uploadedContacts = null;
    @track uploadedOpportunities = null;
    @track uploadedContactRoles = null;

    @track isLoading = false;
    @track status;
    @track progress = {};
    @track jobId;

    polling;

    /* ================= FILE UPLOAD ================= */
    loadFile(event, targetData, targetName) {
        const file = event.target.files[0];
        if (!file) return;

        this[targetName] = file.name;

        const reader = new FileReader();
        reader.onload = e => {
            this[targetData] = this.parseCSV(e.target.result);
            this.toast('File Uploaded', `${file.name} uploaded successfully`, 'success');
        };
        reader.readAsText(file);
    }

    parseCSV(csv) {
        const rows = csv.split(/\r?\n/).filter(r => r.trim());
        if (rows.length < 2) return [];
        const headers = rows[0].split(',').map(h => h.trim());
        return rows.slice(1).map(row => {
            const obj = {};
            row.split(',').forEach((v, i) => obj[headers[i]] = v.trim());
            return obj;
        });
    }

    handleAccountsUpload(e) { this.loadFile(e, 'accountsData', 'uploadedAccounts'); }
    handleContactsUpload(e) { this.loadFile(e, 'contactsData', 'uploadedContacts'); }
    handleOpportunitiesUpload(e) { this.loadFile(e, 'opportunitiesData', 'uploadedOpportunities'); }
    handleContactRolesUpload(e) { this.loadFile(e, 'contactRolesData', 'uploadedContactRoles'); }

    /* ================= TOTALS ================= */
    get totalAccounts() { return this.accountsData.length; }
    get totalContacts() { return this.contactsData.length; }
    get totalOpportunities() { return this.opportunitiesData.length; }
    get totalContactRoles() { return this.contactRolesData.length; }

    get disableStart() {
        return !(this.accountsData.length && this.contactsData.length && this.opportunitiesData.length && this.contactRolesData.length);
    }

    /* ================= MIGRATION ================= */
    startMigration() {
        this.isLoading = true;
        this.status = 'Processing...';

        startMigration({
                accounts: this.accountsData,
                contacts: this.contactsData,
                opportunities: this.opportunitiesData,
                contactRoles: this.contactRolesData
            })
            .then(jobId => {
                this.jobId = jobId;
                this.polling = setInterval(() => this.checkStatus(), 3000);
            })
            .catch(err => this.handleError(err));
    }

    checkStatus() {
        getJobStatus({ jobId: this.jobId })
            .then(job => {
                this.progress = job;
                this.status = job.Status__c;

                if (job.Status__c.startsWith('Completed') || job.Status__c === 'Error') {
                    clearInterval(this.polling);
                    this.isLoading = false;
                }
            })
            .catch(err => this.handleError(err));
    }

    /* ================= DOWNLOADS ================= */
    get accountsErrorUrl() {
        return this.progress.Accounts_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Accounts_Error_File_Id__c}` : null;
    }

    get contactsErrorUrl() {
        return this.progress.Contacts_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Contacts_Error_File_Id__c}` : null;
    }

    get opportunitiesErrorUrl() {
        return this.progress.Opportunities_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Opportunities_Error_File_Id__c}` : null;
    }

    get contactRolesErrorUrl() {
        return this.progress.ContactRoles_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.ContactRoles_Error_File_Id__c}` : null;
    }

    downloadAccountsErrors() { window.open(this.accountsErrorUrl); }
    downloadContactsErrors() { window.open(this.contactsErrorUrl); }
    downloadOpportunitiesErrors() { window.open(this.opportunitiesErrorUrl); }
    downloadContactRolesErrors() { window.open(this.contactRolesErrorUrl); }

    /* ================= ERASE ================= */
    handleCleanData() {
        if (!confirm('Are you sure you want to delete ALL existing Accounts, Contacts, Opportunities, and Contact Roles?')) return;

        this.isLoading = true;

        cleanAllData()
            .then(() => {
                this.handleRefresh();
                this.toast('Success', 'All data erased successfully', 'success');
            })
            .catch(err => this.handleError(err))
            .finally(() => this.isLoading = false);
    }

    /* ================= UTIL ================= */
    handleRefresh() {
        if (this.polling) clearInterval(this.polling);

        this.accountsData = [];
        this.contactsData = [];
        this.opportunitiesData = [];
        this.contactRolesData = [];

        this.uploadedAccounts = null;
        this.uploadedContacts = null;
        this.uploadedOpportunities = null;
        this.uploadedContactRoles = null;

        this.progress = {};
        this.jobId = null;
        this.status = null;
    }

    toast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    handleError(error) {
        if (this.polling) clearInterval(this.polling);
        this.isLoading = false;
        this.toast('Error', error.body ? error.body.message : error.message, 'error');
    }

    get insertedAccounts() { return this.progress.Accounts_Inserted__c || 0; }
    get insertedContacts() { return this.progress.Contacts_Inserted__c || 0; }
    get insertedOpportunities() { return this.progress.Opportunities_Inserted__c || 0; }
    get insertedContactRoles() { return this.progress.ContactRoles_Inserted__c || 0; }
}