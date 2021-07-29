public with sharing class TA_InvestmentUpdate_UpdateStatistics implements packocz.TriggerAction.AfterInsert, packocz.TriggerAction.AfterUpdate, packocz.TriggerAction.AfterDelete {
	private Set<Id> investmentIds;
	private Date fromDate;

	public TA_InvestmentUpdate_UpdateStatistics() {
		this.investmentIds = new Set<Id>();
		this.fromDate = System.today();
	}

	public void afterInsert(List<InvestmentUpdate__c> newList) {
		for (InvestmentUpdate__c iu : newList) {
			this.investmentIds.add(iu.Investment__c);
			if (iu.DateOfUpdate__c < this.fromDate) {
				this.fromDate = iu.DateOfUpdate__c;
			}
		}
		executeJobs();
	}

	public void afterUpdate(List<InvestmentUpdate__c> newList, List<InvestmentUpdate__c> oldList) {
		Map<Id, InvestmentUpdate__c> oldMap = new Map<Id, InvestmentUpdate__c>(oldList);
		for (InvestmentUpdate__c iu : newList) {
			this.investmentIds.add(iu.Investment__c);
			if (iu.DateOfUpdate__c < this.fromDate) {
				this.fromDate = iu.DateOfUpdate__c;
			}
			if (Trigger.isUpdate) {
				this.investmentIds.add(oldMap.get(iu.Id).Investment__c);
				if (oldMap.get(iu.Id).DateOfUpdate__c < this.fromDate) {
					this.fromDate = oldMap.get(iu.Id).DateOfUpdate__c;
				}
			}
		}
		executeJobs();
	}

	public void afterDelete(List<InvestmentUpdate__c> oldList) {
		for (InvestmentUpdate__c iu : oldList) {
			this.investmentIds.add(iu.Investment__c);
			if (iu.DateOfUpdate__c < this.fromDate) {
				this.fromDate = iu.DateOfUpdate__c;
			}
		}
		executeJobs();
	}

	private void executeJobs() {
		if (!this.investmentIds.isEmpty()) {
			Database.executeBatch(new InvestmentStatisticsJob(fromDate, new List<Id>(investmentIds)), 1);
			Database.executeBatch(new InvestmentJob(new List<Id>(investmentIds)), 1);

			this.investmentIds = new Set<Id>();
			this.fromDate = System.today();
		}
	}
}
