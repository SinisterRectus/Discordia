local Snowflake = require('./Snowflake')

local format = string.format

local Embed, property, method = class('Embed', Snowflake)
Embed.__description = "Represents a Discord message embed."

function Embed:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._enabled = data.enabled
	if not self._enabled then return end 
	self._channel_id = data.channel_id
end

function Embed:__tostring()
	return format('%s: %s', self.__name, self._channel_id)
end


local function getGuild(self)
	return self._parent._api:getGuildEmbed(self._guild_id)
end

local function modifyEnabled(self, enabled)
	return self._parent._api:modifyGuildEmbed(self._guild_id, {enabled = enabled})
end

property('enabled', '_enabled', nil, 'string', "Whether the Embed is enabled or not.")
property('channel_id', '_channel_id', nil, 'string', "Embed's channel id (if enabled is true).")

method('getGuild', getGuild, nil, "Returns guild's Embed.")
method('modifyEnabled', modifyEnabled, 'enabled, "Modifies guilds Embeds Enabled attribute.")


return Embed
