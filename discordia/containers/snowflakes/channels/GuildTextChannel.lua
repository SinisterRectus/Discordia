local GuildChannel = require('./GuildChannel')
local TextChannel = require('./TextChannel')

local format = string.format

local GuildTextChannel, get, set = class('GuildTextChannel', GuildChannel, TextChannel)

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
	GuildTextChannel._update(self, data)
end

get('mentionString', function(self)
	return format('<#%s>', self._id)
end, 'string')

function GuildTextChannel:_update(data)
	GuildChannel._update(self, data)
	TextChannel._update(self, data)
end

set('topic', function(self, topic)
	local success, data = self._parent._parent._api:modifyChannel(self._id, {topic = topic})
	if success then self._topic = data.topic end
	return success
end)

return GuildTextChannel
