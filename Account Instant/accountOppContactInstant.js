import { LightningElement, track } from 'lwc';
import getAccountRecordTypes
from '@salesforce/apex/BulkHierarchyCreatorCtrl.getAccountRecordTypes';

import getOpportunityStages
from '@salesforce/apex/BulkHierarchyCreatorCtrl.getOpportunityStages';

import createHierarchy
from '@salesforce/apex/BulkHierarchyCreatorCtrl.createHierarchy';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkHierarchyCreator extends LightningElement {

    count = 1;
    prefix = 'ACC';
    recordTypeId;
    stageName;

    @track recordTypeOptions = [];
    @track stageOptions = [];
    @track createdRows = [];

    connectedCallback() {
        getAccountRecordTypes().then(res => {
            this.recordTypeOptions = res.map(r => ({
                label: r.Name,
                value: r.Id
            }));
        });

        getOpportunityStages().then(res => {
            this.stageOptions = res.map(s => ({
                label: s,
                value: s
            }));
        });
    }

    handleCount(e) { this.count = e.detail.value; }
    handlePrefix(e) { this.prefix = e.detail.value.toUpperCase(); }
    handleRecordType(e) { this.recordTypeId = e.detail.value; }
    handleStage(e) { this.stageName = e.detail.value; }

    handleCreate() {
        createHierarchy({
                recordTypeId: this.recordTypeId,
                stageName: this.stageName,
                count: this.count,
                prefix: this.prefix
            })
            .then(result => {
                this.createdRows = result;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Hierarchy records created',
                        variant: 'success'
                    })
                );
            });
    }

    // ---------------- CSV Download ----------------
    downloadCSV() {
        let csv =
            'Account Id,Account Name,Opportunity Id,Opportunity Name,Contact Id,Contact Name\n';

        this.createdRows.forEach(r => {
            csv += `${r.accountId},${r.accountName},${r.opportunityId},${r.opportunityName},${r.contactId},${r.contactName}\n`;
        });

        const element = document.createElement('a');
        element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        element.target = '_self';
        element.download = 'Created_Records.csv';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }
}