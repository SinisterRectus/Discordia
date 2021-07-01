local class = require('../class')

local ActivitySecrets, get = class('ActivitySecrets')

function ActivitySecrets:__init(data)
	self._join = data.join
	self._spectate = data.spectate
	self._match = data.match
end

function get:join()
	return self._join
end

function get:spectate()
	return self._spectate
end

function get:match()
	return self._match
end

return ActivitySecrets
