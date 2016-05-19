local bit = require('bit')
local Permissions = class('Permissions')


local flags = 
{
	createInstantInvite = 0x00000001,
	kickMembers = 0x00000002,
	banMembers = 0x00000004,
	administrator = 0x00000008, 
	manageChannels = 0x00000010,
	manageGuild = 0x00000020,
	readMessages = 0x00000400,
	sendMessages = 0x00000800,
	sendTTSMessages = 0x00001000,
	manageMessages = 0x00002000,
	embedLinks = 0x00004000,
	attachFiles = 0x00008000,
	readMessageHistory = 0x00010000,
	mentionEveryone = 0x00020000,
	connect = 0x00100000,
	speak = 0x00200000,
	muteMembers = 0x00400000,
	deafenMembers = 0x00800000,
	moveMembers = 0x01000000,
	useVoiceActivity = 0x02000000,
	changeNickname = 0x04000000,
	manageNickname = 0x08000000,
	manageRoles = 0x10000000,
}

function Permissions:__init(a)
	self.value = a or 0
end

function Permissions:set( flag )
	if flags[flag] then
		return Permissions( bit.bor( self.value, flags[flag] ) )		
	else
		error( "Permission flag '"..flag.."' not recognized" )
	end
end

function Permissions:unset( flag )
	if flags[flag] then
		return Permissions( bit.band( self.value, bit.bnot( flags[flag] ) ) )	
	else
		error( "Permission flag '"..flag.."' not recognized" )
	end
end

function Permissions:hasPermission( flag )
	if flags[flag] then
		return bit.band( self.value, flags[flag] )
	else
		error( "Permission flag '"..flag.."' not recognized" )
	end
end

function Permissions:toDec()
	return self.value
end

return Permissions