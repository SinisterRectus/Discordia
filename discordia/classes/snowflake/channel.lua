local Base = require('./base')
local endpoints = require('../../endpoints')

local Channel = class('Channel', Base)

function Channel:__init(data, client)
	Base.__init(self, data.id, client)
end

function Channel:delete(data)
	self.client:request('DELETE', {endpoints.channels, self.id})
end

return Channel
