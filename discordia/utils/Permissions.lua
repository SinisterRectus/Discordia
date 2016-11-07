local bit = require('bit')

local format = string.format
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local sort, insert, concat = table.sort, table.insert, table.concat

local Permissions, property, method = class('Permissions')
Permissions.__description = "Wrapper for a Discord permissions bit set."

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
	sendTextToSpeech	= 0x00001000, -- text
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
	manageRoles			= 0x10000000, -- general
	manageWebhooks		= 0x20000000, -- general
	manageEmojis		= 0x40000000, -- general
}

local all = 0
for _, value in pairs(flags) do
	all = bor(all, value)
end

function Permissions:__init(value)
	self._value = tonumber(value) or 0
end

function Permissions:__tostring()
	local tbl = self:toArray()
	if #tbl == 0 then
		return 'Permissions: 0 (none)'
	else
		sort(tbl)
		return format('Permissions: %i (%s)', self._value, concat(tbl, ', '))
	end
end

function Permissions:__eq(other)
	return self.__name == other.__name and self._value == other._value
end

local function enable(self, ...)
	local value = self._value
	for i = 1, select('#', ...) do
		local flag = select(i, ...)
		local v = flags[flag]
		if not v then error('Invalid permission flag: ' .. tostring(flag)) end
		value = bor(value, v)
	end
	self._value = value
end

local function disable(self, ...)
	local value = self._value
	for i = 1, select('#', ...) do
		local flag = select(i, ...)
		local v = flags[flag]
		if not v then error('Invalid permission flag: ' .. tostring(flag)) end
		value = band(value, bnot(v))
	end
	self._value = value
end

local function has(self, ...)
	local value = self._value
	for i = 1, select('#', ...) do
		local flag = select(i, ...)
		local v = flags[flag]
		assert(v, 'Invalid permission flag: ' .. tostring(flag))
		if band(value, v) == 0 then return false end
	end
	return true
end

local function enableAll(self)
	self._value = all
end

local function disableAll(self)
	self._value = 0
end

local function toHex(self)
	return format('0x%08X', self._value)
end

local function toTable(self)
	local ret = {}
	for flag, value in pairs(flags) do
		ret[flag] = band(self._value, value) > 0
	end
	return ret
end

local function toArray(self)
	local ret = {}
	for flag, value in pairs(flags) do
		if band(self._value, value) > 0 then
			insert(ret, flag)
		end
	end
	return ret
end

local function union(self, other) -- in either
	return Permissions(bor(self._value, other._value))
end

local function intersection(self, other) -- in both
	return Permissions(band(self._value, other._value))
end

local function difference(self, other) -- not in both
	return Permissions(bxor(self._value, other._value))
end

local function complement(self, other) -- in other not in self
	local value = other and other._value or all
	return Permissions(band(bnot(self._value), value))
end

function Permissions:copy()
	return Permissions(self._value)
end

property('value', '_value', nil, 'number', "Decimal representing the total permissions")

method('enable', enable, 'flag[, ...]', "Enables a permission or permissions.")
method('disable', disable, 'flag[, ...]', "Disables a permission or permissions.")
method('has', has, 'flag[, ...]', "Returns a boolean indicating whether a permission or permissions is/are enabled.")
method('enableAll', enableAll, nil, "Enables all permissions.")
method('disableAll', disableAll, nil, "Disables all permissions.")
method('toHex', toHex, nil, "Returns a hex string for the permission's value.")
method('toTable', toTable, nil, "Returns a Lua table indicating whether each permission flag is enabled.")
method('toArray', toArray, nil, "Returns an array-like Lua table of all enabled flags.")
method('union', union, 'other', "Returns a new Permissions object with the permissions that are in self or other (bitwise OR).")
method('intersection', intersection, 'other', "Returns a new Permissions object with the permissions that are in self and other (bitwise AND).")
method('difference', difference, 'other', "Returns a new Permissions object with the permissions that in self or other, but not both (bitwise XOR).")
method('complement', complement, '[other]', "Returns a new Permissions object with the permissions that are in other (or all) but not self.")

return Permissions
