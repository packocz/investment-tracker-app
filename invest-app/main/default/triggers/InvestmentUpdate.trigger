trigger InvestmentUpdate on InvestmentUpdate__c(before insert, after insert, after update, after delete) {
	System.debug('test');
	new packocz.MetadataTriggerHandler().run();
}
