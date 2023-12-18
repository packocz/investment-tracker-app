@namespaceAccessible
public without sharing class TA_InvestmentUpdate_SetCurrency implements packocz.TriggerAction.BeforeInsert {
	@namespaceAccessible
	public void beforeInsert(List<InvestmentUpdate__c> newList) {
		System.debug('test');
		Set<Id> investmentIds = new Set<Id>();
		for (InvestmentUpdate__c iu : newList) {
			investmentIds.add(iu.Investment__c);
		}
		Map<Id, Investment__c> investmentCurrencies = new Map<Id, Investment__c>(
			[SELECT Id, CurrencyIsoCode FROM Investment__c WHERE Id IN :investmentIds]
		);
		for (InvestmentUpdate__c iu : newList) {
			iu.CurrencyIsoCode = investmentCurrencies.get(iu.Investment__c).CurrencyIsoCode;
		}
	}
}
