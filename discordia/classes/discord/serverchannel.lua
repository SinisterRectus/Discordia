local Base = require('./base')
local Invite = require('./invite')
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
end

function ServerChannel:edit(name, position, topic, bitrate)
	local body = {
		name = name or self.name,
		position = position or self.position,
		topic = topic or self.topic,
		bitrate = bitrate or self.bitrate
	}
	self.client:request('PATCH', {endpoints.channels, self.id}, body)
end

function ServerChannel:setName(name)
	self:edit(name, nil, nil, nil)
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
