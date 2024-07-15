local Time = require('../libs/utils/Time')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue
local assertError = utils.assertError

for n = -64, 64 do
	n = 2 ^ n
	assertEqual(Time.fromWeeks(n):toWeeks(), n)
	assertEqual(Time.fromDays(n):toDays(), n)
	assertEqual(Time.fromHours(n):toHours(), n)
	assertEqual(Time.fromMinutes(n):toMinutes(), n)
	assertEqual(Time.fromSeconds(n):toSeconds(), n)
	assertEqual(Time.fromMilliseconds(n):toMilliseconds(), n)
	assertEqual(Time.fromMicroseconds(n):toMicroseconds(), n)
end

do -- empty set
	local t = Time()
	local tbl = t:toTable()
	assertEqual(tbl.weeks, 0)
	assertEqual(tbl.days, 0)
	assertEqual(tbl.hours, 0)
	assertEqual(tbl.minutes, 0)
	assertEqual(tbl.seconds, 0)
	assertEqual(tbl.milliseconds, 0)
	assertEqual(tbl.microseconds, 0)
	assertEqual(t:toString(), '0 microseconds')
end

do -- no overflow
	local t = Time.fromTable {
		weeks = 2, days = 3, hours = 4, minutes = 5,
		seconds = 6, milliseconds = 7, microseconds = 8,
	}
	local tbl = t:toTable()
	assertEqual(tbl.weeks, 2)
	assertEqual(tbl.days, 3)
	assertEqual(tbl.hours, 4)
	assertEqual(tbl.minutes, 5)
	assertEqual(tbl.seconds, 6)
	assertEqual(tbl.milliseconds, 7)
	assertEqual(tbl.microseconds, 8)
	assertEqual(t:toString(), '2 weeks, 3 days, 4 hours, 5 minutes, 6 seconds, 7 milliseconds, 8 microseconds')
end

do -- normalization for perfect overflows
	local t = Time.fromTable {
		weeks = 0, days = 7, hours = 24, minutes = 60,
		seconds = 60,	milliseconds = 1000, microseconds = 1001,
	}
	local tbl = t:toTable()
	assertEqual(tbl.weeks, 1)
	assertEqual(tbl.days, 1)
	assertEqual(tbl.hours, 1)
	assertEqual(tbl.minutes, 1)
	assertEqual(tbl.seconds, 1)
	assertEqual(tbl.milliseconds, 1)
	assertEqual(tbl.microseconds, 1)
	assertEqual(t:toString(), '1 week, 1 day, 1 hour, 1 minute, 1 second, 1 millisecond, 1 microsecond')
end

do -- normalization with negative integers
	local t = Time.fromTable {
		weeks = 2, days = -3, hours = 4, minutes = -5,
		seconds = 6, milliseconds = -7, microseconds = 8,
	}
	local tbl = t:toTable()
	assertEqual(tbl.weeks, 1)
	assertEqual(tbl.days, 4)
	assertEqual(tbl.hours, 3)
	assertEqual(tbl.minutes, 55)
	assertEqual(tbl.seconds, 5)
	assertEqual(tbl.milliseconds, 993)
	assertEqual(tbl.microseconds, 8)
	assertEqual(t:toString(), '1 week, 4 days, 3 hours, 55 minutes, 5 seconds, 993 milliseconds, 8 microseconds')
end

do -- reversibility for integers
	local t = Time(1)
	assertEqual(t:toMicroseconds(), 1)
	local tbl = t:toTable()
	assertEqual(tbl.microseconds, 1)
	assertEqual(t:toString(), '1 microsecond')
	assertEqual(Time.fromTable(tbl):toMicroseconds(), 1)
end

do -- reversibility for floats
	local t = Time(1.8)
	assertEqual(t:toMicroseconds(), 1.8)
	local tbl = t:toTable()
	assertEqual(tbl.microseconds, 1) -- WARNING: value truncated
	assertEqual(t:toString(), '1 microsecond') -- WARNING: value truncated
	assertEqual(Time.fromTable(tbl):toMicroseconds(), 1) -- WARNING: not reversible
end

assertTrue(Time(1) == Time(1))
assertTrue(Time(1) ~= Time(2))

assertTrue(Time(1) < Time(2))
assertTrue(Time(2) > Time(1))

assertTrue(Time(1) <= Time(1))
assertTrue(Time(1) >= Time(1))

assertTrue(Time(1) <= Time(2))
assertTrue(Time(2) >= Time(1))

assertTrue(Time(1) == Time(1))
assertTrue(Time(1) ~= Time(-1))

assertTrue(Time(-1) < Time(1))
assertTrue(Time(1) > Time(-1))

assertTrue(Time(-1) <= Time(-1))
assertTrue(Time(-1) >= Time(-1))

assertTrue(Time(-1) <= Time(1))
assertTrue(Time(1) >= Time(-1))

assertEqual(Time(1) + Time(2), Time(3))
assertEqual(Time(2) + Time(1), Time(3))

assertEqual(Time(1) - Time(2), Time(-1))
assertEqual(Time(2) - Time(1), Time(1))

assertEqual(Time(2) * 2, Time(4))
assertEqual(2 * Time(2), Time(4))
assertEqual(Time(2) / 2, Time(1))

assertEqual(Time(2) * -2, Time(-4))
assertEqual(-2 * Time(2), Time(-4))
assertEqual(Time(2) / -2, Time(-1))

assertEqual(Time(12) % Time(3), Time(0))
assertEqual(Time(12) % Time(5), Time(2))

assertEqual(Time.fromWeeks(1) + Time.fromDays(1), Time.fromDays(8))
assertEqual(Time.fromDays(1) + Time.fromHours(1), Time.fromHours(25))
assertEqual(Time.fromHours(1) + Time.fromMinutes(1), Time.fromMinutes(61))
assertEqual(Time.fromMinutes(1) + Time.fromSeconds(1), Time.fromSeconds(61))
assertEqual(Time.fromSeconds(1) + Time.fromMilliseconds(1), Time.fromMilliseconds(1001))
assertEqual(Time.fromMilliseconds(1) + Time.fromMicroseconds(1), Time.fromMicroseconds(1001))

assertEqual(Time.fromWeeks(0.5), Time.fromDays(3.5))
assertEqual(Time.fromDays(0.5), Time.fromHours(12))
assertEqual(Time.fromHours(0.5), Time.fromMinutes(30))
assertEqual(Time.fromMinutes(0.5), Time.fromSeconds(30))
assertEqual(Time.fromSeconds(0.5), Time.fromMilliseconds(500))
assertEqual(Time.fromMilliseconds(0.5), Time.fromMicroseconds(500))

assertError(function() return 1 / Time(1) end, 'division not commutative')
assertError(function() return Time(1) < {} end, 'cannot perform operation')
assertError(function() return Time(1) > {} end, 'cannot perform operation')
assertError(function() return Time(1) <= {} end, 'cannot perform operation')
assertError(function() return Time(1) >= {} end, 'cannot perform operation')
assertError(function() return Time(1) + {} end, 'cannot perform operation')
assertError(function() return Time(1) - {} end, 'cannot perform operation')
assertError(function() return Time(1) % {} end, 'cannot perform operation')
assertError(function() return Time(1) * {} end, 'cannot perform operation')
assertError(function() return Time(1) / {} end, 'cannot perform operation')
assertError(function() return Time(1) < 1 end, 'cannot perform operation')
assertError(function() return Time(1) > 1 end, 'cannot perform operation')
assertError(function() return Time(1) <= 1 end, 'cannot perform operation')
assertError(function() return Time(1) >= 1 end, 'cannot perform operation')
assertError(function() return Time(1) + 1 end, 'cannot perform operation')
assertError(function() return Time(1) - 1 end, 'cannot perform operation')
assertError(function() return Time(1) % 1 end, 'cannot perform operation')
assertError(function() return Time({}) end, 'expected number, received table')
assertError(function() return Time.fromTable {weeks = {}} end, 'expected number, received table')