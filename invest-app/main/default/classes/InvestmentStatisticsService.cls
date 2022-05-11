public with sharing class InvestmentStatisticsService {
	private static final Integer SNAPSHOT_LENGTH = 7;
	private Id investmentId;
	private String currencyCode;
	private Date fromDate;
	private Integer fromWeekNumber;
	private Map<Integer, InvestmentSnapshot__c> snapshots;
	private Map<Integer, Decimal> deposits;
	private Map<Integer, Decimal> withdrawals;
	private Map<Integer, Decimal> balances;
	private Integer toWeekNumber;

	public InvestmentStatisticsService(Id investmentId, Date fromDate) {
		this.investmentId = investmentId;
		this.currencyCode = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = TRUE].IsoCode;
		this.fromDate = fromDate;
		this.fromWeekNumber = weekNumber(this.fromDate);

		loadSnapshots();
		loadUpdates();
	}

	public void process() {
		Integer weekNumber = this.fromWeekNumber;
		List<Integer> allWeekNumbers = new List<Integer>(this.balances.keySet());
		allWeekNumbers.addAll(this.deposits.keySet());
		allWeekNumbers.addAll(this.withdrawals.keySet());
		allWeekNumbers.sort();
		Integer lastWeekNumber = allWeekNumbers[allWeekNumbers.size() - 1];
		Date weekDate = this.FromDate.toStartOfWeek();

		Decimal previousTotal;
		while (weekNumber <= lastWeekNumber) {
			InvestmentSnapshot__c thisWeek = this.snapshots.containsKey(weekNumber)
				? this.snapshots.get(weekNumber)
				: new InvestmentSnapshot__c(
						Investment__c = this.investmentId,
						PeriodStartDate__c = weekDate,
						PeriodLengthDays__c = 7,
						StartingInvestmentAmount__c = 0,
						CurrencyIsoCode = this.currencyCode
				  );

			thisWeek.Deposits__c = this.deposits.containsKey(weekNumber) ? this.deposits.get(weekNumber) : 0;
			thisWeek.Withdrawals__c = this.withdrawals.containsKey(weekNumber) ? this.withdrawals.get(weekNumber) : 0;

			if (previousTotal != null) {
				thisWeek.StartingInvestmentAmount__c = previousTotal;
			}

			thisWeek.Balance__c = this.balances.containsKey(weekNumber)
				? this.balances.get(weekNumber)
				: (thisWeek.Deposits__c + thisWeek.Withdrawals__c + thisWeek.StartingInvestmentAmount__c);
			for (Integer i = 0; i < 1000; i++) {
				System.debug('dome');
				Integer x = 0;
			}
			this.snapshots.put(weekNumber, thisWeek);

			previousTotal = thisWeek.Balance__c;

			this.deposits.remove(weekNumber);
			this.withdrawals.remove(weekNumber);
			this.balances.remove(weekNumber);

			weekNumber++;
			weekDate = weekDate + 7;
		}
		this.toWeekNumber = weekNumber;
	}

	private void loadUpdates() {
		this.deposits = new Map<Integer, Decimal>();
		for (AggregateResult depositsInWeek : [
			SELECT WEEK_IN_YEAR(DateOfUpdate__c), SUM(Amount__c)
			FROM InvestmentUpdate__c
			WHERE Investment__c = :this.investmentId AND RecordType.DeveloperName = 'Deposit'
			GROUP BY WEEK_IN_YEAR(DateOfUpdate__c)
		]) {
			Integer weekNumber = (Integer) depositsInWeek.get('expr0');
			Decimal deposit = (Decimal) depositsInWeek.get('expr1');
			this.deposits.put(weekNumber, deposit);
		}

		this.withdrawals = new Map<Integer, Decimal>();
		for (AggregateResult withdrawalsInWeek : [
			SELECT WEEK_IN_YEAR(DateOfUpdate__c), SUM(Amount__c)
			FROM InvestmentUpdate__c
			WHERE Investment__c = :this.investmentId AND RecordType.DeveloperName = 'Withdrawal'
			GROUP BY WEEK_IN_YEAR(DateOfUpdate__c)
		]) {
			Integer weekNumber = (Integer) withdrawalsInWeek.get('expr0');
			Decimal withdrawal = (Decimal) withdrawalsInWeek.get('expr1');
			this.withdrawals.put(weekNumber, withdrawal);
		}

		this.balances = new Map<Integer, Decimal>();
		for (AggregateResult balanceInWeek : [
			SELECT WEEK_IN_YEAR(DateOfUpdate__c), AVG(Amount__c)
			FROM InvestmentUpdate__c
			WHERE Investment__c = :this.investmentId AND RecordType.DeveloperName = 'BalanceUpdate'
			GROUP BY WEEK_IN_YEAR(DateOfUpdate__c)
		]) {
			Integer weekNumber = (Integer) balanceInWeek.get('expr0');
			Decimal balance = (Decimal) balanceInWeek.get('expr1');
			this.balances.put(weekNumber, balance);
		}
	}

	public void save() {
		upsert this.snapshots.values();
		for (Integer week = this.fromWeekNumber + 1; week < this.toWeekNumber; week++) {
			this.snapshots.get(week).PreviousSnapshot__c = this.snapshots.get(week - 1).Id;
		}
		update this.snapshots.values();
	}

	private void loadSnapshots() {
		this.snapshots = new Map<Integer, InvestmentSnapshot__c>();
		for (InvestmentSnapshot__c snap : [
			SELECT
				Id,
				PeriodStartDate__c,
				PeriodEndDate__c,
				PeriodLengthDays__c,
				PreviousSnapshot__c,
				StartingInvestmentAmount__c,
				InvestedAmount__c,
				Balance__c,
				Deposits__c,
				Withdrawals__c,
				WeekNumber__c,
				CurrencyIsoCode
			FROM InvestmentSnapshot__c
			WHERE Investment__c = :this.investmentId AND WeekNumber__c >= :this.fromWeekNumber
			ORDER BY PeriodStartDate__c ASC
		]) {
			this.snapshots.put(Integer.valueOf(snap.WeekNumber__c), snap);
		}
	}

	private Integer weekNumber(Date requiredDate) {
		return Math.mod(
			(Integer) Math.floor((Date.newInstance(2018, 1, 1).daysBetween(requiredDate.toStartOfWeek())) / 7),
			52
		);
	}
}
