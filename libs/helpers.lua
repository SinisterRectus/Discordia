local uv = require('uv')

-- local function merge(sink, source)
-- 	for k, v in pairs(source) do
-- 		sink[k] = v
-- 	end
-- 	return sink
-- end

-- local function has(tbl, value)
-- 	for _, v in pairs(tbl) do
-- 		if v == value then return true end
-- 	end
-- end

local function benchmark(n, fn, ...)

	local _ = {}

	collectgarbage('collect')
	collectgarbage('collect')
	collectgarbage('stop')

	local m1 = collectgarbage('count')
	local t1 = uv.hrtime()

	for i = 1, n do
		_[i] = fn(...)
	end

	local t2 = uv.hrtime()
	local m2 = collectgarbage('count')

	collectgarbage('restart')

	return (t2 - t1) / n, (m2 - m1) / n, ...

end

local function assertResume(thread, ...)
	local success, err = coroutine.resume(thread, ...)
	if not success then
		error(debug.traceback(thread, err))
	end
end

local function setTimeout(ms, callback, ...)
	local timer = uv.new_timer()
	local n = select('#', ...)
	if n == 0 then
		timer:start(ms, 0, function()
			timer:close()
			return callback()
		end)
	elseif n == 1 then
		local arg = ...
		timer:start(ms, 0, function()
			timer:close()
			return callback(arg)
		end)
	else
		local args = {...}
		timer:start(ms, 0, function()
			timer:close()
			return callback(unpack(args, 1, n))
		end)
	end
	return timer
end

local function setInterval(ms, callback, ...)
	local timer = uv.new_timer()
	local n = select('#', ...)
	if n == 0 then
		timer:start(ms, ms, function()
			return callback()
		end)
	elseif n == 1 then
		local arg = ...
		timer:start(ms, ms, function()
			return callback(arg)
		end)
	else
		local args = {...}
		timer:start(ms, ms, function()
			return callback(unpack(args, 1, n))
		end)
	end
	return timer
end

local function clearTimer(timer)
	if timer:is_closing() then return end
	timer:stop()
	timer:close()
end

local function sleep(ms)
	local thread = coroutine.running()
	local timer = uv.new_timer()
	timer:start(ms, 0, function()
		timer:close()
		return assertResume(thread)
	end)
	return coroutine.yield()
end

return {
	benchmark = benchmark,
	assertResume = assertResume,
	setTimeout = setTimeout,
	setInterval = setInterval,
	clearTimer = clearTimer,
	sleep = sleep,
}