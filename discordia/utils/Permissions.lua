local bit = require('bit')

local format = string.format
local band, bor = bit.band, bit.bor
local sort, insert, concat = table.sort, table.insert, table.concat

local Permissions = class('Permissions')

local flags = {
	createInstantInvite	= 0x00000001, -- general
	kickMembers			= 0x00000002, -- general
	banMembers			= 0x00000004, -- general
	administrator		= 0x00000008, -- general
	manageChannels		= 0x00000010, -- general
	manageGuild			= 0x00000020, -- general
	readMessages		= 0x00000400, -- text
	sendMessages		= 0x00000800, -- text
	sendTTSMessages		= 0x00001000, -- text
	manageMessages		= 0x00002000, -- text
	embedLinks			= 0x00004000, -- text
	attachFiles			= 0x00008000, -- text
	readMessageHistory	= 0x00010000, -- text
	mentionEveryone		= 0x00020000, -- text
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

function Permissions:__init(value)
	self.value = value or 0
end

function Permissions:__tostring()
	local tbl = self:toTable()
	if #tbl == 0 then
		return 'Permissions: 0 (none)'
	else
		sort(tbl)
		return format('Permissions: %i (%s)', self.value, concat(tbl, ', '))
	end
end

function Permissions.__eq(other)
	return self.__class == other.__class and self.value == other.value
end

function Permissions:enable(flag)
	local value = flags[flag]
	assert(value, 'Invalid permission flag: ' .. tostring(flag))
	self.value = bor(self.value, value)
end

function Permissions:disable(flag)
	local value = flags[flag]
	assert(value, 'Invalid permission flag: ' .. tostring(flag))
	self.value = band(self.value, bit.bnot(value))
end

function Permissions:has(flag)
	local value = flags[flag]
	assert(value, 'Invalid permission flag: ' .. tostring(flag))
	return band(self.value, value) > 0
end

function Permissions:enableAll()
	for flag, value in pairs(flags) do
		self.value = bor(self.value, value)
	end
end

function Permissions:disableAll()
	self.value = 0
end

function Permissions:toDec()
	return self.value
end

function Permissions:toHex()
	return format('0x%08X', self.value)
end

function Permissions:toTable()
	local ret = {}
	for flag, value in pairs(flags) do
		if band(self.value, value) > 0 then
			insert(ret, flag)
		end
	end
	return ret
end

function Permissions:copy()
	return Permissions(self:toDec())
end

return Permissions
