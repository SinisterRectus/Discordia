local Date = require('../libs/utils/Date')
local Time = require('../libs/utils/Time')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue
local assertError = utils.assertError

for n = 16, 32 do
	n = 2 ^ n
	assertEqual(Date.fromSeconds(n):toSeconds(), n)
	assertEqual(Date.fromMilliseconds(n):toMilliseconds(), n)
	assertEqual(Date.fromMicroseconds(n):toMicroseconds(), n)
	assertTrue(tonumber(Date.fromSnowflake(tostring(n)):toSnowflake()) <= n) -- WARNING: conversion not reversible
	for m = 16, 32 do
		m = 2 ^ m
		local d = Date(n, m)
		assertEqual(Date.fromISO(d:toISO()), d)
		assertEqual(Date.fromTable(d:toTable()), d)
		assertEqual(Date.fromTableUTC(d:toTableUTC()), d)
	end
end

local t = 1584132886

do -- test no usec
	local d = Date(t)
	assertEqual(select(1, d:toParts()), t)
	assertEqual(select(2, d:toParts()), 0)
	assertEqual(d:toISO(), '2020-03-13T20:54:46')
end

do -- test large usec
	local d = Date(t, 100000)
	assertEqual(select(1, d:toParts()), t)
	assertEqual(select(2, d:toParts()), 100000)
	assertEqual(d:toISO(), '2020-03-13T20:54:46.100000')
end

do -- test small usec
	local d = Date(t, 1)
	assertEqual(select(1, d:toParts()), t)
	assertEqual(select(2, d:toParts()), 1)
	assertEqual(d:toISO(), '2020-03-13T20:54:46.000001')
end

do -- test usec overflow
	local d = Date(t, 1234567)
	assertEqual(select(1, d:toParts()), t + 1)
	assertEqual(select(2, d:toParts()), 234567)
	assertEqual(d:toISO(), '2020-03-13T20:54:47.234567')
end

do -- test perfect usec overflow
	local d = Date(t, 1000000)
	assertEqual(select(1, d:toParts()), t + 1)
	assertEqual(select(2, d:toParts()), 0)
	assertEqual(d:toISO(), '2020-03-13T20:54:47')
end

assertEqual(Date.fromISO('2020'), Date.fromTableUTC {
	year = 2020,
})
assertEqual(Date.fromISO('2020-03'), Date.fromTableUTC {
	year = 2020, month = 3,
})
assertEqual(Date.fromISO('2020-03-13'), Date.fromTableUTC {
	year = 2020, month = 3, day = 13,
})
assertEqual(Date.fromISO('2020-03-13T20'), Date.fromTableUTC {
	year = 2020, month = 3, day = 13,
	hour = 20,
})
assertEqual(Date.fromISO('2020-03-13T20:54'), Date.fromTableUTC {
	year = 2020, month = 3, day = 13,
	hour = 20, min = 54,
})
assertEqual(Date.fromISO('2020-03-13T20:54:47'), Date.fromTableUTC {
	year = 2020, month = 3, day = 13,
	hour = 20, min = 54, sec = 47,
})
assertEqual(Date.fromISO('2020-03-13T20:54:47.234567'), Date.fromTableUTC {
	year = 2020, month = 3, day = 13,
	hour = 20, min = 54, sec = 47, usec = 234567,
})
assertEqual(Date.fromISO('2020-03-13T20:54:47.234567+03:00'), Date.fromTableUTC {
	year = 2020, month = 3, day = 13,
	hour = 20, min = 54, sec = 47, usec = 234567, zone = "+03:00"
})

assertTrue(Date(1) == Date(1))
assertTrue(Date(1) ~= Date(2))

assertTrue(Date(1) < Date(2))
assertTrue(Date(2) > Date(1))

assertTrue(Date(1) <= Date(1))
assertTrue(Date(1) >= Date(1))

assertTrue(Date(1) <= Date(2))
assertTrue(Date(2) >= Date(1))

assertEqual(Date.fromSeconds(1) + Time.fromSeconds(2), Date.fromSeconds(3))
assertEqual(Date.fromSeconds(2) + Time.fromSeconds(1), Date.fromSeconds(3))
assertEqual(Date.fromSeconds(2) - Time.fromSeconds(1), Date.fromSeconds(1))
assertEqual(Date.fromSeconds(1) - Date.fromSeconds(2), Time.fromSeconds(-1))
assertEqual(Date.fromSeconds(2) - Date.fromSeconds(1), Time.fromSeconds(1))

assertError(function() return Date(-1) end, 'expected minimum 0, received -1')
assertError(function() return Date(1.1) end, 'expected integer, received 1.1')
assertError(function() return Date(1, 1.1) end, 'expected integer, received 1.1')
assertError(function() return Date(1, -1) end, 'expected minimum 0, received -1')

assertError(function() return Date():toISO('') end, 'invalid ISO 8601 separator')
assertError(function() return Date():toISO('  ') end, 'invalid ISO 8601 separator')

assertError(function() return Date.fromTable() end, 'expected table, received nil')
assertError(function() return Date.fromTable(1) end, 'expected table, received number')
assertError(function() return Date.fromTableUTC() end, 'expected table, received nil')
assertError(function() return Date.fromTableUTC(1) end, 'expected table, received number')

assertError(function() return Date.fromISO() end, 'expected string, received nil')
assertError(function() return Date.fromISO('202-03-13T20:54:47') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-3-13T20:54:47') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-3T20:54:47') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T0:54:47') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:4:47') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:54:7') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13  20:54:47') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:54:47.2') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:54:47.234') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:54:47.2345') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:54:47.23456') end, 'invalid ISO 8601 string')
assertError(function() return Date.fromISO('2020-03-13T20:54:47.2345678') end, 'invalid ISO 8601 string')

assertError(function() return Date() + Time(1.8) end, 'cannot perform operation')
assertError(function() return Date() - Time(1.8) end, 'cannot perform operation')
assertError(function() return Date.fromSeconds(1) + Time.fromSeconds(-2) end, 'cannot perform operation')
assertError(function() return Date.fromSeconds(1) - Time.fromSeconds(2) end, 'cannot perform operation')

assertError(function() return Date(1) + Date(1) end, 'cannot perform operation')
assertError(function() return Time(1) + Date(1) end, 'cannot perform operation')
assertError(function() return Time(1) - Date(1) end, 'cannot perform operation')

assertError(function() return Date(1) < {} end, 'cannot perform operation')
assertError(function() return Date(1) > {} end, 'cannot perform operation')
assertError(function() return Date(1) <= {} end, 'cannot perform operation')
assertError(function() return Date(1) >= {} end, 'cannot perform operation')
assertError(function() return Date(1) + {} end, 'cannot perform operation')
assertError(function() return Date(1) - {} end, 'cannot perform operation')
assertError(function() return Date(1) % {} end, 'cannot perform operation')
assertError(function() return Date(1) * {} end, 'cannot perform operation')
assertError(function() return Date(1) / {} end, 'cannot perform operation')
assertError(function() return Date(1) < 1 end, 'cannot perform operation')
assertError(function() return Date(1) > 1 end, 'cannot perform operation')
assertError(function() return Date(1) <= 1 end, 'cannot perform operation')
assertError(function() return Date(1) >= 1 end, 'cannot perform operation')
assertError(function() return Date(1) + 1 end, 'cannot perform operation')
assertError(function() return Date(1) - 1 end, 'cannot perform operation')
assertError(function() return Date(1) % 1 end, 'cannot perform operation')
assertError(function() return Date(1) * 1 end, 'cannot perform operation')
assertError(function() return Date(1) / 1 end, 'cannot perform operation')

assertError(function() return Date(2^128):toISO() end, 'time could not be converted to date')
assertError(function() return Date(2^128):toString() end, 'time could not be converted to date')
assertError(function() return Date(2^128):toTable() end, 'time could not be converted to date')
assertError(function() return Date(2^128):toTableUTC() end, 'time could not be converted to date')

assertError(function() return Date.fromISO('1969') end, 'date could not be converted to time')
assertError(function() return Date.fromTableUTC {year = 1969} end, 'date could not be converted to time')
