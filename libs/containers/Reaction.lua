local Container = require('utils/Container')

local Reaction = require('class')('Reaction', Container)

function Reaction:__init(data, parent)
    Container.__init(self, data, parent) -- TODO: load emoji (unicode vs custom local vs custom external)
end

return Reaction
