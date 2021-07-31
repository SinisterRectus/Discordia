local class = require('../class')

local Struct = require('./Struct')

local ActivitySecrets, get = class('ActivitySecrets', Struct)

function ActivitySecrets:__init(data)
	Struct.__init(self, data)
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
