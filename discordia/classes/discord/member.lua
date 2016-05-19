local User = require('./user')
local endpoints = require('../../endpoints')
local dateToTime = require('../../utils').dateToTime

local Member = class('Member', User)

function Member:__init(data, server)

	User.__init(self, data.user, server.client)

	self.deaf = data.deaf -- boolean
	self.mute = data.mute -- boolean
	self.roles = data.roles -- table of role IDs
	self.server = server -- object
	self.status = 'offline' -- string
	self.nickname = data.nick -- string
	self.joinedAt = dateToTime(data.joinedAt) -- number

	-- don't call update, it gets confused

end

function Member:_update(data)
	if data.user and data.user.username then
		User._update(self, data.user)
	end
	self.status = data.status or self.status or 'offline'-- string
	self.gameName = data.game and data.game.name or self.gameName-- string or nil
end

-- Member:set* Functions
local setParams = { 'nickname', 'roles', 'mute', 'deaf' }
function Member:set( options )
	local body = {}
	for i,param in ipairs( setParams ) do
		body[param] = options[param] or self[param]
	end
	
	-- adjust to fit protocol
	body.nick, body.nickname = body.nickname or '', nil
	
	data = self.client:request('PATCH', {endpoints.servers, self.server.id, 'members', self.id}, body)
	if data then return Member(data, self.server) end
end
for i,param in ipairs( setParams ) do
	local Param = (param:gsub("^%l", string.upper))
	Member[ "set"..Param ] = function( self, value ) return self:set( { [param] = value } ) end
end

return Member
