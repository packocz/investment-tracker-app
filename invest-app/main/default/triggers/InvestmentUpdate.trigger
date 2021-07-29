trigger InvestmentUpdate on InvestmentUpdate__c(before insert, after insert, after update, after delete) {
	new packocz.MetadataTriggerHandler().run();
}
