local Logger = require('../libs/utils/Logger')
local utils = require('./utils')

local assertNil = utils.assertNil
local assertEqual = utils.assertEqual
local assertError = utils.assertError

do
	local logger = Logger('none')
	assertNil(logger:log('critical', '%s', 'critical test'))
	assertNil(logger:log('error', '%s', 'error test'))
	assertNil(logger:log('warning', '%s', 'warning test'))
	assertNil(logger:log('info', '%s', 'info test'))
	assertNil(logger:log('debug', '%s', 'debug test'))
end

do
	local logger = Logger('critical')
	assertEqual(logger:log('critical', '%s', 'critical test'), 'critical test')
	assertNil(logger:log('error', '%s', 'error test'))
	assertNil(logger:log('warning', '%s', 'warning test'))
	assertNil(logger:log('info', '%s', 'info test'))
	assertNil(logger:log('debug', '%s', 'debug test'))
end

do
	local logger = Logger('error')
	assertEqual(logger:log('critical', '%s', 'critical test'), 'critical test')
	assertEqual(logger:log('error', '%s', 'error test'), 'error test')
	assertNil(logger:log('warning', '%s', 'warning test'))
	assertNil(logger:log('info', '%s', 'info test'))
	assertNil(logger:log('debug', '%s', 'debug test'))
end

do
	local logger = Logger('warning')
	assertEqual(logger:log('critical', '%s', 'critical test'), 'critical test')
	assertEqual(logger:log('error', '%s', 'error test'), 'error test')
	assertEqual(logger:log('warning', '%s', 'warning test'), 'warning test')
	assertNil(logger:log('info', '%s', 'info test'))
	assertNil(logger:log('debug', '%s', 'debug test'))
end

do
	local logger = Logger('info')
	assertEqual(logger:log('critical', '%s', 'critical test'), 'critical test')
	assertEqual(logger:log('error', '%s', 'error test'), 'error test')
	assertEqual(logger:log('warning', '%s', 'warning test'), 'warning test')
	assertEqual(logger:log('info', '%s', 'info test'), 'info test')
	assertNil(logger:log('debug', '%s', 'debug test'))
end

do
	local logger = Logger('debug')
	assertEqual(logger:log('critical', '%s', 'critical test'), 'critical test')
	assertEqual(logger:log('error', '%s', 'error test'), 'error test')
	assertEqual(logger:log('warning', '%s', 'warning test'), 'warning test')
	assertEqual(logger:log('info', '%s', 'info test'), 'info test')
	assertEqual(logger:log('debug', '%s', 'debug test'), 'debug test')
end

assertError(function() return Logger(-1) end, 'invalid enumeration value: -1')
assertError(function() return Logger('abc') end, 'invalid enumeration name: abc')
assertError(function() return Logger(1, 1) end, 'expected string, received number')
assertError(function() return Logger(1):log() end, 'invalid enumeration value: nil')
assertError(function() return Logger(1):log('abc') end, 'invalid enumeration name: abc')
assertError(function() return Logger(1):log(1) end, 'expected string, received nil')
assertError(function() return Logger(1):log(1, 1) end, 'expected string, received number')
