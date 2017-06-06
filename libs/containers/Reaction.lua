local Container = require('utils/Container')

local Reaction = require('class')('Reaction', Container)

function Reaction:__init(data, parent)
    Container.__init(self, data, parent)
    self._emoji_id = data.emoji.id
    self._emoji_name = data.emoji.name
end

return Reaction
