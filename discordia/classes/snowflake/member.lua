local User = require('./user')
local Role = require('./role')
local endpoints = require('../../endpoints')
local dateToTime = require('../../utils').dateToTime

local Member = class('Member', User)

function Member:__init(data, server)

	User.__init(self, data.user, server.client)

	self.deaf = data.deaf -- boolean, whether the user is deaf (can't hear others in voice channel)
	self.mute = data.mute -- boolean, whether the user is mute (can't broadcast their beautiful voice)
	self.server = server -- Server, self explanatory
	self.status = 'offline' -- string, self explanatory
	self.nickname = data.nick -- string, self explanatory
	self.name = self.nickname or self.username -- string, self explanatory
	self.joinedAt = dateToTime(data.joinedAt) -- number, self explanatory
	
	-- _update adds a variable called gameName if the user is playing a game, which is a string
	-- make sure to check to see if it's nil before indexing it

	self.roles = {} -- table, self explanatory
	for _, roleId in ipairs(data.roles) do
		self.roles[roleId] = server.roles[roleId]
	end

end

-- don't call this, it gets confused

function Member:_update(data)
	if data.user and data.user.username then
		User._update(self, data.user)
	end
	self.status = data.status or self.status or 'offline'
	self.gameName = data.game and data.game.name or self.gameName -- see above, this sets the gameName
end

-- the following chunk of code does the following:
-- it creates 4 functions, called setNickname, setRoles, setMute, setDeaf
-- they basically set the nickname, roles, and whether the user is mute or deaf
-- setNickname takes a string which it changes user.nickname to
-- setRoles takes a table with role ID's (not role objects) and sets the user's roles
-- setMute and setDeaf both take a boolean, and sets whether the user is muted or deaf respectively

local setParams = {'nickname', 'roles', 'mute', 'deaf'}
for _, param in ipairs(setParams) do
	local fname = "set" .. (param:gsub("^%l", string.upper))
	Member[fname] = function(self, value) return self:set({[param] = value}) end
end

-- this function is quite different from setRoles or setNickname etc.
-- it sets all 4 at once
-- as it is not very easy to figure out, let me give you an example
--[[
Member:set({
	nickname: "Nick",
	roles: {Role1.id, Role2.id},
	mute: false,
	deaf: false
})
]]-- as shown in the example above, it sets all 4 at once.
-- you can't set only 3 or only 2, it sets all 4 and no less.

function Member:set(options)
	local body = {}
	for _, param in ipairs(setParams) do
		body[param] = options[param] or self[param]
	end
	body.nick, body.nickname = body.nickname or '', nil -- adjust for compatibility
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'members', self.id}, body)
end

-- this function kicks the user from the server 
-- if the bot has the appropriate permissions, of course

function Member:kick()
	return self.client:request('DELETE', {endpoints.servers, self.server.id, 'members', self.id})
end

return Member
