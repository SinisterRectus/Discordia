local json = require('json')

local methods = {}

function methods:setBitrate(bitrate)
	return self:modifyChannel(self.id, {bitrate = bitrate or json.null})
end

function methods:setUserLimit(userLimit)
	return self:modifyChannel(self.id, {user_limit = userLimit or json.null})
end

-- TODO: join/leave

local getters = {}

function getters:bitrate()
	return self._bitrate
end

function getters:userLimit()
	return self._user_limit
end

return {
	methods = methods,
	getters = getters,
}
