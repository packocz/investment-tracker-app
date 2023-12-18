public with sharing class InvestmentStatisticsJob implements Database.Batchable<Investment__c> {
	private Date startDate;
	private List<Id> investmentIds;

	public InvestmentStatisticsJob(Date startDate, List<Id> investmentIds) {
		this.startDate = startDate;
		this.investmentIds = investmentIds;
	}


	public List<Investment__c> start(Database.BatchableContext bc) {
		return [SELECT Id FROM Investment__c WHERE Id IN :this.investmentIds];
	}

	public void execute(Database.BatchableContext bc, List<Investment__c> scope) {
		for (Investment__c investment : scope) {
			InvestmentStatisticsService stats = new InvestmentStatisticsService(investment.Id, this.startDate);
			stats.process();
			stats.save();
		}
	}

	public void finish(Database.BatchableContext bc) {
	}
}
