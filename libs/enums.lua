local names = {}

local function enum(tbl)
	local call = {}
	for k, v in pairs(tbl) do
		assert(type(k) == 'string', 'enum name must be a string')
		call[v] = k
	end
	return setmetatable({}, {
		__call = function(_, k)
			return call[k]
		end,
		__index = function(_, k)
			return tbl[k]
		end,
		__pairs = function()
			local k, v
			return function()
				k, v = next(tbl, k)
				return k, v
			end
		end,
		__newindex = function()
			return error('cannot overwrite enumeration')
		end,
		__tostring = function(self)
			return 'enumeration: ' .. names[self]
		end,
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

proxy.status = {
	online       = 'online',
	idle         = 'idle',
	dnd          = 'dnd',
	invisible    = 'invisible', -- only sent?
	offline      = 'offline', -- only received?
}

proxy.activityType = {
	playing   = 0,
	streaming = 1,
	listening = 2,
	custom    = 4,
}

proxy.logLevel = {
	none    = 0,
	error   = 1,
	warning = 2,
	info    = 3,
	debug   = 4,
}

proxy.gatewayIntent = {
	guilds                = 0x00000001, -- 1 << 0
	guildMembers          = 0x00000002, -- 1 << 1
	guildBans             = 0x00000004, -- 1 << 2
	guildEmojis           = 0x00000008, -- 1 << 3
	guildIntegrations     = 0x00000010, -- 1 << 4
	guildWebhooks         = 0x00000020, -- 1 << 5
	guildInvites          = 0x00000040, -- 1 << 6
	guildVoiceStates      = 0x00000080, -- 1 << 7
	guildPresences        = 0x00000100, -- 1 << 8
	guildMessages         = 0x00000200, -- 1 << 9
	guildMessageReactions = 0x00000400, -- 1 << 10
	guildMessageTyping    = 0x00000800, -- 1 << 11
	directMessage         = 0x00001000, -- 1 << 12
	directMessageRections = 0x00002000, -- 1 << 13
	directMessageTyping   = 0x00004000, -- 1 << 14
}

return proxy
