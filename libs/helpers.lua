local uv = require('uv')

local hrtime = uv.hrtime
local insert = table.insert
local format, byte, gsub = string.format, string.byte, string.gsub

local function toPercent(char)
	return format('%%%02X', byte(char))
end

local function urlEncode(obj)
	return (gsub(tostring(obj), '%W', toPercent))
end

local function attachQuery(url, query)
	for k, v in pairs(query) do
		insert(url, #url == 1 and '?' or '&')
		insert(url, urlEncode(k))
		insert(url, '=')
		insert(url, urlEncode(v))
	end
end

local function benchmark(n, fn, ...)

	local _ = {}

	collectgarbage()
	collectgarbage()
	local m1 = collectgarbage('count')
	local t1 = hrtime()

	for i = 1, n do
		_[i] = fn(...)
	end

	collectgarbage()
	collectgarbage()
	local m2 = collectgarbage('count')
	local t2 = hrtime()

	return (m2 - m1) / n, (t2 - t1) / n

end

local function newProxy(tbl, newIndex)
	return setmetatable({}, {
		__index = function(_, k)
			return tbl[k]
		end,
		__newindex = newIndex,
		__pairs = function()
			local k, v
			return function()
				k, v = next(tbl, k)
				return k, v
			end
		end
	})
end

return {
	urlEncode = urlEncode,
	attachQuery = attachQuery,
	benchmark = benchmark,
	newProxy = newProxy,
}
