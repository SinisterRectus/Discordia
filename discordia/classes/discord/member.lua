local User = require('./user')
local endpoints = require('../../endpoints')

local Member = class('Member', User)

function Member:__init(data, server)

	User.__init(self, data.user, server.client)

	self.deaf = data.deaf -- boolean
	self.mute = data.mute -- boolean
	self.roles = data.roles -- table of role IDs
	self.server = server -- object
	self.status = 'offline' -- string
	self.joinedAt = data.joinedAt -- string

	-- don't call update, it gets confused

end

function Member:_update(data)
	if data.user and data.user.username then
		User._update(self, data.user)
	end
	self.status = data.status or 'offline'-- string
	self.gameName = data.game and data.game.name -- string or nil
end

function Member:setNickname(nickName, server)
	local body = {nick = nickName}
	self:request('PATCH', {endpoints.servers, server.id, 'members', self.id}, body)
end

return Member
