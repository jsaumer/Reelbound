## GDScript port of sim/tests/test_pools.py -- D3's invariants (bankroll
## only drains, winnings only accumulates) checked in both implementations.
extends GutTest


func test_spend_from_bankroll_decreases_bankroll():
	var pools := Pools.new(100.0)
	pools.spend_from_bankroll(30.0)
	assert_eq(pools.bankroll, 70.0)


func test_pending_commits_fully_into_winnings():
	var pools := Pools.new(100.0)
	pools.add_to_pending(25.0)
	pools.commit_pending_to_winnings()
	assert_eq(pools.winnings, 25.0)
	assert_eq(pools.pending, 0.0)


func test_bankroll_only_ever_drains_across_many_spins():
	# D3: bankroll never receives a payout, no matter how large.
	var pools := Pools.new(50.0)
	var bankroll_history := [pools.bankroll]
	var spins := [[5.0, 0.0], [5.0, 40.0], [5.0, 0.0], [5.0, 100.0], [5.0, 0.0]]
	for pair in spins:
		pools.spend_from_bankroll(pair[0])
		pools.add_to_pending(pair[1])
		pools.commit_pending_to_winnings()
		bankroll_history.append(pools.bankroll)

	for i in range(1, bankroll_history.size()):
		assert_lte(bankroll_history[i], bankroll_history[i - 1])
	assert_eq(pools.bankroll, 25.0)   # 50 - 5*5, unaffected by wins
	assert_eq(pools.winnings, 140.0)  # 0 + 40 + 100


func test_winnings_never_decreases():
	var pools := Pools.new(100.0)
	var winnings_history := [pools.winnings]
	for payout in [10.0, 0.0, 5.0, 0.0, 0.0]:
		pools.spend_from_bankroll(1.0)
		pools.add_to_pending(payout)
		pools.commit_pending_to_winnings()
		winnings_history.append(pools.winnings)

	for i in range(1, winnings_history.size()):
		assert_gte(winnings_history[i], winnings_history[i - 1])
