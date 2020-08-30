local typing = require('../typing')
local json = require('json')

local checkInteger= typing.checkInteger

local methods = {}

function methods:setBitrate(bitrate)
	return self:_modify({bitrate = bitrate and checkInteger(bitrate) or json.null})
end

function methods:setUserLimit(userLimit)
	return self:_modify({user_limit = userLimit or json.null})
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
