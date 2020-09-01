local Invite = require('../containers/Invite')

local typing = require('../typing')
local json = require('json')

local checkType, checkSnowflake = typing.checkType, typing.checkSnowflake
local checkInteger= typing.checkInteger

local methods = {}

function methods:setName(name)
	return self:_modify {name = name and checkType('string', name) or json.null}
end

function methods:setCategory(parentId)
	return self:_modify {parent_id = parentId and checkSnowflake(parentId) or json.null}
end

-- TODO: sorting

function methods:createInvite(payload)
	if payload then
		checkType('table', payload)
	end
	local data, err = self.client.api:createChannelInvite(self.id, {
		max_age = payload.maxAge and checkInteger(payload.maxAge),
		max_uses = payload.maxUses and checkInteger(payload.maxUses),
		temporary = payload.temporary ~= nil and checkType('boolean', payload.temporary),
		unique = payload.unique ~= nil and checkType('boolean', payload.unique),
	})
	if data then
		return Invite(data, self.client)
	else
		return nil, err
	end
end

function methods:getInvites()
	local data, err = self.client.api:getGuildInvites(self.id)
	if data then
		for i, v in ipairs(data) do
			data[i] = Invite(v, self)
		end
		return data
	else
		return nil, err
	end
end

-- TODO: permission overwrites

local getters = {}

function getters:name()
	return self._name
end

function getters:position()
	return self._position
end

function getters:guildId()
	return self._guild_id
end

function getters:parentId()
	return self._parent_id
end

return {
	methods = methods,
	getters = getters,
}
