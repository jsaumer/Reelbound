extends GutTest


func test_below_smallest_tier_is_silent():
	assert_eq(BigWinBanner.tier_label(5.0), "")
	assert_eq(BigWinBanner.tier_label(9.99), "")


func test_nice_win_tier():
	assert_eq(BigWinBanner.tier_label(10.0), "NICE WIN!")
	assert_eq(BigWinBanner.tier_label(29.99), "NICE WIN!")


func test_big_win_tier():
	assert_eq(BigWinBanner.tier_label(30.0), "BIG WIN!")
	assert_eq(BigWinBanner.tier_label(99.99), "BIG WIN!")


func test_huge_win_tier():
	assert_eq(BigWinBanner.tier_label(100.0), "HUGE WIN!")
	assert_eq(BigWinBanner.tier_label(400.0), "HUGE WIN!")
