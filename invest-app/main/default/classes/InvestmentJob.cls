public with sharing class InvestmentJob implements Database.Batchable<Investment__c> {
	private List<Id> investmentIds;

	public InvestmentJob(List<Id> investmentIds) {
		this.investmentIds = investmentIds;
	}
	public List<Investment__c> start(Database.BatchableContext bc) {
		return [SELECT Id FROM Investment__c WHERE Id IN :this.investmentIds];
	}
	public void execute(Database.BatchableContext bc, List<Investment__c> scope) {
		for (Investment__c investment : scope) {
			InvestmentService investmentService = new InvestmentService(investment.Id);
		}
	}
	public void finish(Database.BatchableContext bc) {
	}

	public void someMethod() {
	}
}
