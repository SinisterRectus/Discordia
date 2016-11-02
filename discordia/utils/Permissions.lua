local bit = require('bit')

local format = string.format
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local sort, insert, concat = table.sort, table.insert, table.concat

local Permissions, get = class('Permissions')

local flags = {
	createInstantInvite	= 0x00000001, -- general
	kickMembers			= 0x00000002, -- general
	banMembers			= 0x00000004, -- general
	administrator		= 0x00000008, -- general
	manageChannels		= 0x00000010, -- general
	manageGuild			= 0x00000020, -- general
	addReactions		= 0x00000040, -- text
	readMessages		= 0x00000400, -- text
	sendMessages		= 0x00000800, -- text
	sendTTSMessages		= 0x00001000, -- text
	manageMessages		= 0x00002000, -- text
	embedLinks			= 0x00004000, -- text
	attachFiles			= 0x00008000, -- text
	readMessageHistory	= 0x00010000, -- text
	mentionEveryone		= 0x00020000, -- text
	useExternalEmojis	= 0x00040000, -- text
	connect				= 0x00100000, -- voice
	speak				= 0x00200000, -- voice
	muteMembers			= 0x00400000, -- voice
	deafenMembers		= 0x00800000, -- voice
	moveMembers			= 0x01000000, -- voice
	useVoiceActivity	= 0x02000000, -- voice
	changeNickname		= 0x04000000, -- general
	manageNicknames		= 0x08000000, -- general
	managePermissions	= 0x10000000, -- general
	manageWebhooks		= 0x20000000, -- general
	manageEmojis		= 0x40000000, -- general
}

local all = 0
for flag, value in pairs(flags) do
	all = bor(all, value)
end

function Permissions:__init(value)
	self._value = tonumber(value) or 0
end

get('value', '_value')

function Permissions:__tostring()
	local tbl = self:toTable()
	if #tbl == 0 then
		return 'Permissions: 0 (none)'
	else
		sort(tbl)
		return format('Permissions: %i (%s)', self._value, concat(tbl, ', '))
	end
end

function Permissions.__eq(other)
	return self.__class == other.__class and self._value == other._value
end

function Permissions:enable(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local flag = select(i, ...)
		local v = flags[flag]
		assert(v, 'Invalid permission flag: ' .. tostring(flag))
		value = bor(value, v)
	end
	self._value = value
end

function Permissions:disable(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local flag = select(i, ...)
		local v = flags[flag]
		assert(v, 'Invalid permission flag: ' .. tostring(flag))
		value = band(value, bnot(v))
	end
	self._value = value
end

function Permissions:has(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local flag = select(i, ...)
		local v = flags[flag]
		assert(v, 'Invalid permission flag: ' .. tostring(flag))
		if band(value, v) == 0 then return false end
	end
	return true
end

function Permissions:enableAll()
	self._value = all
end

function Permissions:disableAll()
	self._value = 0
end

function Permissions:toHex()
	return format('0x%08X', self._value)
end

function Permissions:toTable()
	local ret = {}
	for flag, value in pairs(flags) do
		if band(self._value, value) > 0 then
			insert(ret, flag)
		end
	end
	return ret
end

function Permissions:union(other) -- in either
	return Permissions(bor(self._value, other._value))
end

function Permissions:intersection(other) -- in both
	return Permissions(band(self._value, other._value))
end

function Permissions:difference(other) -- not in both
	return Permissions(bxor(self._value, other._value))
end

function Permissions:complement(other) -- in other not in self
	local value = other and other._value or all
	return Permissions(band(bnot(self._value), value))
end

function Permissions:copy()
	return Permissions(self._value)
end

return Permissions
