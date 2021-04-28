@IsTest
private class InvestmentServiceTest {
	private static final Id deposit = Schema.SObjectType.InvestmentUpdate__c.getRecordTypeInfosByDeveloperName()
		.get('Deposit')
		.getRecordTypeId();
	private static final Id balanceUpdate = Schema.SObjectType.InvestmentUpdate__c.getRecordTypeInfosByDeveloperName()
		.get('BalanceUpdate')
		.getRecordTypeId();

	@IsTest
	static void testInvestments() {
		InvestmentPlan__c plan = new InvestmentPlan__c(Name = 'Test Investment Plan');
		insert plan;

		Investment__c investment = new Investment__c(Name = 'Test Investment', InvestmentPlan__c = plan.Id);
		insert investment;

		Test.startTest();

		List<InvestmentUpdate__c> investmentUpdates = new List<InvestmentUpdate__c>();
		investmentUpdates.add(
			new InvestmentUpdate__c(
				Investment__c = investment.Id,
				RecordTypeId = deposit,
				DateOfUpdate__c = System.today(),
				Amount__c = 1000
			)
		);
		investmentUpdates.add(
			new InvestmentUpdate__c(
				Investment__c = investment.Id,
				RecordTypeId = balanceUpdate,
				DateOfUpdate__c = System.today(),
				Amount__c = 1100
			)
		);

		insert investmentUpdates;

		Test.stopTest();

		Investment__c updatedInvestment = [
			SELECT Id, CurrentBalance__c, CurrentRoiAmount__c
			FROM Investment__c
			WHERE Id = :investment.Id
		];
		System.assertEquals(1100, updatedInvestment.CurrentBalance__c, 'Balance not updated correctly');
		System.assertEquals(100, updatedInvestment.CurrentRoiAmount__c, 'Current ROI not updated correctly');
	}
}
