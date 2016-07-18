local bit = require('bit')

local Permissions = class('Permissions')

local flags = {
	createInstantInvite	= 0x00000001, -- general, default
	kickMembers			= 0x00000002, -- general, elevated
	banMembers			= 0x00000004, -- general, elevated
	administrator		= 0x00000008, -- general, elevated
	manageChannels		= 0x00000010, -- general, elevated
	manageGuild			= 0x00000020, -- general, elevated
	readMessages		= 0x00000400, -- text, default
	sendMessages		= 0x00000800, -- text, default
	sendTTSMessages		= 0x00001000, -- text, default
	manageMessages		= 0x00002000, -- text, elevated
	embedLinks			= 0x00004000, -- text, default
	attachFiles			= 0x00008000, -- text, default
	readMessageHistory	= 0x00010000, -- text, default
	mentionEveryone		= 0x00020000, -- text, default
	connect				= 0x00100000, -- voice, default
	speak				= 0x00200000, -- voice, default
	muteMembers			= 0x00400000, -- voice, intermediate
	deafenMembers		= 0x00800000, -- voice, intermediate
	moveMembers			= 0x01000000, -- voice, intermediate
	useVoiceActivity	= 0x02000000, -- voice, default
	changeNickname		= 0x04000000, -- general, default
	manageNicknames		= 0x08000000, -- general, intermediate
	manageRoles			= 0x10000000, -- general, elevated
}

function Permissions:__init(value)
	self.value = value or 0
end

function Permissions:__tostring()
	local tbl = self:toTable()
	table.sort(tbl)
	return 'Permissions: ' .. table.concat(tbl, ', ')
end

function Permissions.__eq(other)
	return self:isSameTypeAs(other) and self.value == other.value
end

function Permissions:set(flag)
	local value = flags[flag]
	assert(value, 'Invalid permission flag: ' .. tostring(flag))
	self.value = bit.bor(self.value, value)
end

function Permissions:unset(flag)
	local value = flags[flag]
	assert(value, 'Invalid permission flag: ' .. tostring(flag))
	self.value = bit.band(self.value, bit.bnot(value))
end

function Permissions:has(flag)
	local value = flags[flag]
	assert(value, 'Invalid permission flag: ' .. tostring(flag))
	return bit.band(self.value, value) > 0
end

function Permissions:toDec()
	return self.value
end

function Permissions:toHex()
	return string.format('0x%08X', self.value)
end

function Permissions:toTable()
	local ret = {}
	for flag, value in pairs(flags) do
		if bit.band(self.value, value) > 0 then
			table.insert(ret, flag)
		end
	end
	return ret
end

return Permissions
