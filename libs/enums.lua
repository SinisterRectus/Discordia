local names = {}

local function enum(tbl)
	local call = {}
	for k, v in pairs(tbl) do
		if type(k) ~= 'string' then
			return error('enumeration name must be a string')
		end
		call[v] = k
	end
	return setmetatable({}, {
		__index = function(_, k)
			if not tbl[k] then
				return error('invalid enumeration name: ' .. tostring(k))
			end
			return tbl[k]
		end,
		__newindex = function()
			return error('cannot overwrite enumeration')
		end,
		__pairs = function()
			local k, v
			return function()
				k, v = next(tbl, k)
				return k, v
			end
		end,
		__call = function(_, v)
			if tbl[v] then
				return v, tbl[v]
			end
			local n = tonumber(v)
			if call[n] then
				return call[n], n
			end
			local s = tostring(v)
			if call[s] then
				return call[s], s
			end
			return error('invalid enumeration: ' .. tostring(v))
		end,
		__tostring = function(self)
			return 'enumeration: ' .. names[self]
		end
	})
end

local enums = {}
local proxy = setmetatable({}, {
	__index = function(_, k)
		return enums[k]
	end,
	__newindex = function(_, k, v)
		if enums[k] then
			return error('cannot overwrite enumeration')
		end
		v = enum(v)
		names[v] = k
		enums[k] = v
	end,
	__pairs = function()
		local k, v
		return function()
			k, v = next(enums, k)
			return k, v
		end
	end,
})

proxy.timestampStyle = {
	shortTime     = 't',
	longTime      = 'T',
	shortDate     = 'd',
	longDate      = 'D',
	shortDateTime = 'f',
	longDateTime  = 'F',
	relativeTime  = 'R',
}

proxy.logLevel = {
	none     = 0,
	critical = 1,
	error    = 2,
	warning  = 3,
	info     = 4,
	debug    = 5,
}

return proxy