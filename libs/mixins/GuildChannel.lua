local json = require('json')

local methods = {}

function methods:setName(name)
	return self:modifyChannel(self.id, {name = name or json.null})
end

function methods:setCategory(parentId)
	return self:modifyChannel(self.id, {parent_id = parentId or json.null})
end

-- TODO: sorting

function methods:createInvite(payload)
	return self.client:createChannelInvite(self.id, payload)
end

function methods:getInvites()
	return self.client:getChannelInvites(self.id)
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
