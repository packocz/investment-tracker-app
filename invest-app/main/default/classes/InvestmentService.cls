public with sharing class InvestmentService {
	private Id investmentId;
	private Investment__c investment;

	public InvestmentService(Id investmentId) {
		this.investmentId = investmentId;
		System.debug('some test');
		this.investment = [
			SELECT
				Id,
				CurrentBalance__c,
				(
					SELECT Id, Amount__c
					FROM InvestmentUpdates__r
					WHERE RecordType.DeveloperName = 'BalanceUpdate'
					ORDER BY DateOfUpdate__c DESC
					LIMIT 1
				)
			FROM Investment__c
			WHERE Id = :this.investmentId
		];
	}

	public void save() {
		if (
			!this.investment.InvestmentUpdates__r.isEmpty() &&
			this.investment.CurrentBalance__c <> this.investment.InvestmentUpdates__r[0].Amount__c
		) {
			update new Investment__c(
				Id = this.investmentId,
				CurrentBalance__c = this.investment.InvestmentUpdates__r[0].Amount__c
			);
		}
	}
}
