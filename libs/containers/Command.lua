local Snowflake = require('./Snowflake')
local CommandOption = require('../structs/CommandOption')

local json = require('json')
local class = require('../class')
local helpers = require('../helpers')

local Command, get = class('Command', Snowflake)

function Command:__init(data, client)
	Snowflake.__init(self, data, client)
	self._options = data.options and helpers.structs(CommandOption, data.options)
end

function Command:modify(payload)
	if self.guildId then
		return self.client:editGuildApplicationCommand(self.applicationId, self.guildId, self.id, payload)
	else
		return self.client:editGlobalApplicationCommand(self.applicationId, self.id, payload)
	end
end

function Command:delete()
	if self.guildId then
		return self.client:deleteGuildApplicationCommand(self.applicationId, self.guildId, self.id)
	else
		return self.client:deleteGlobalApplicationCommand(self.applicationId, self.id)
	end
end

function Command:setName(name)
	return self:modify {name = name or json.null}
end

function Command:setDescription(description)
	return self:modify {description = description or json.null}
end

function Command:setOptions(options)
	return self:modify {options = options or json.null}
end

function Command:setDefaultPermission(defaultPermission)
	return self:modify {defaultPermission = defaultPermission or json.null}
end

function get:applicationId()
	return self._application_id
end

function get:guildId()
	return self._guild_id
end

function get:name()
	return self._name
end

function get:description()
	return self._description
end

function get:options()
	return self._options
end

function get:defaultPermission()
	return self._default_permission or false
end

return Command
