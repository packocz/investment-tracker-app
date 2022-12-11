public with sharing class InvestmentStatisticsJob implements Database.Batchable<Investment__c> {
	private Date startDate;
	private List<Id> investmentIds;

	public String unusedProperty;

	public InvestmentStatisticsJob(Date startDate, List<Id> investmentIds) {
		this.startDate = startDate;
		this.investmentIds = investmentIds;
	}
	public List<Investment__c> start(Database.BatchableContext bc) {
		return [SELECT Id FROM Investment__c WHERE Id IN :this.investmentIds];
	}
	public void execute(Database.BatchableContext bc, List<Investment__c> scope) {
	}

	public void finish(Database.BatchableContext bc) {
	}
	Decimal x = 9;
}
