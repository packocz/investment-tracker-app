trigger InvestmentUpdate on InvestmentUpdate__c(after insert, after update, after delete) {
	Set<Id> investmentIds = new Set<Id>();
	Date fromDate = System.today();
	if (Trigger.isDelete) {
		for (InvestmentUpdate__c iu : Trigger.old) {
			investmentIds.add(iu.Investment__c);
			if (iu.DateOfUpdate__c < fromDate) {
				fromDate = iu.DateOfUpdate__c;
			}
		}
	} else {
		for (InvestmentUpdate__c iu : Trigger.new) {
			investmentIds.add(iu.Investment__c);
			if (iu.DateOfUpdate__c < fromDate) {
				fromDate = iu.DateOfUpdate__c;
			}
			if (Trigger.isUpdate) {
				investmentIds.add(Trigger.oldMap.get(iu.Id).Investment__c);
				if (Trigger.oldMap.get(iu.Id).DateOfUpdate__c < fromDate) {
					fromDate = Trigger.oldMap.get(iu.Id).DateOfUpdate__c;
				}
			}
		}
	}
	if (!investmentIds.isEmpty()) {
		Database.executeBatch(new InvestmentStatisticsJob(fromDate, new List<Id>(investmentIds)), 1);
		Database.executeBatch(new InvestmentJob(new List<Id>(investmentIds)), 1);
	}
}
