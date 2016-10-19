local User = require('./user')
local Role = require('./role')
local endpoints = require('../../endpoints')
local dateToTime = require('../../utils').dateToTime

local Member = class('Member', User)

function Member:__init(data, server)

	User.__init(self, data.user, server.client)

	self.deaf = data.deaf
	self.mute = data.mute
	self.server = server
	self.status = 'offline'
	self.nickname = data.nick
	self.name = self.nickname or self.username
	self.joinedAt = dateToTime(data.joinedAt)

	self.roles = {}
	for _, roleId in ipairs(data.roles) do
		self.roles[roleId] = server.roles[roleId]
	end

	-- don't call update, it gets confused

end

function Member:_update(data)
	if data.user and data.user.username then
		User._update(self, data.user)
	end
	self.status = data.status or self.status or 'offline'
	self.gameName = data.game and data.game.name or self.gameName
	if data.roles then
		self.roles = {}
		for _, roleId in ipairs(data.roles) do
			self.roles[roleId] = self.server.roles[roleId]
		end
	end
	self.nickname = data.nick
end

local setParams = {'nickname', 'roles', 'mute', 'deaf'}
for _, param in ipairs(setParams) do
	local fname = "set" .. (param:gsub("^%l", string.upper))
	Member[fname] = function(self, value) return self:set({[param] = value}) end
end

function Member:set(options)
	local body = {}
	for _, param in ipairs(setParams) do
		body[param] = options[param] or self[param]
	end
	body.nick, body.nickname = body.nickname or '', nil -- adjust for compatibility
	local roles = {}
	for _, role in pairs(body.roles) do
		table.insert(roles, role.id)
	end
	body.roles = roles
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'members', self.id}, body)
end

function Member:kick()
	return self.client:request('DELETE', {endpoints.servers, self.server.id, 'members', self.id})
end

return Member
