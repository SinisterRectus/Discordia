local Container = require('utils/Container')

local Invite = require('class')('Invite', Container)

function Invite:__init(data, parent)
	Container.__init(self, data, parent)
end

function Invite:__hash()
	return self._code
end

return Invite
