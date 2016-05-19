local Base = require('./base')
local Invite = require('./invite')
local Permissions = require('./permissions')
local endpoints = require('../../endpoints')

local ServerChannel = class('ServerChannel', Base)

function ServerChannel:__init(data, server)

	Base.__init(self, data.id, server.client)
	self.server = server

	self.type = data.type
	self:_update(data)

end

function ServerChannel:_update(data)
	self.name = data.name
	self.topic = data.topic
	self.position = data.position	
	self.permissionOverwrites = data.permissionOverwrites
	
	-- Convert permissions to use classes
	for i,overwrite in ipairs( self.permissionOverwrites ) do
		overwrite.allow = Permissions(overwrite.allow)
		overwrite.deny = Permissions(overwrite.deny)
	end
end

local setParams = { 'name', 'topic', 'position', 'bitrate' }
function ServerChannel:set( options )
	local body = {}
	for i,param in ipairs( setParams ) do
		body[param] = options[param] or self[param]
	end
	
	self.client:request('PATCH', {endpoints.channels, self.id}, body)
end

-- ServerChannel:edit deprecated by ServerChannel:set
function ServerChannel:edit(name, position, topic, bitrate)
	return self:set( { name = name, position = position, topic = topic, bitrate = bitrate } )
end

function ServerChannel:editPermissionsFor( target, allow, deny )	
	local body = { id = target.id, allow = allow:toDec(), deny = deny:toDec() }
	if target.__name == 'Role' then
		body.type = 'role'
	elseif target.__name == 'Member' then
		body.type = 'member'
	else
		error( "Unrecognized target type" )
	end
	
	self.client:request('PUT', {endpoints.channels, self.id, 'permissions', target.id }, body)
end

function ServerChannel:getPermissionsFor( target )
	local target_type
	if target.__name == 'Role' then
		target_type = 'role'
	elseif target.__name == 'Member' then
		target_type = 'member'
	else
		error( "Unrecognized target type" )
	end
	
	for i,overwrite in ipairs( self.permissionOverwrites ) do
		if overwrite.id == target.id and overwrite.type == target_type then
			return overwrite
		end
	end
end

function ServerChannel:createInvite()
	local data = self.client:request('POST', {endpoints.channels, self.id, 'invites'}, {})
	return Invite(data, self.server)
end

function ServerChannel:getInvites()
	local inviteTable = self.client:request('GET', {endpoints.channels, self.id, 'invites'})
	local invites = {}
	for _, inviteData in ipairs(inviteTable) do
		local invite = Invite(inviteData, self.server)
		invites[invite.code] = invite
	end
	return invites
end

function ServerChannel:delete(data)
	self.client:request('DELETE', {endpoints.channels, self.id})
end

return ServerChannel
