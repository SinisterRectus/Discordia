local class = require('../class')
local helpers = require('../helpers')

local ActivityTimestamps = require('./ActivityTimestamps')
local PartialEmoji = require('./PartialEmoji')
local ActivityParty = require('./ActivityParty')
local ActivityAssets = require('./ActivityAssets')
local ActivitySecrets = require('./ActivitySecrets')
local ActivityButton = require('./ActivityButton')

local Activity, get = class('Activity')

function Activity:__init(data)
	self._name = data.name
	self._type = data.type
	self._url = data.url
	self._created_at = data.created_at
	self._application_id = data.application_id
	self._details = data.details
	self._state = data.state
	self._instance = data.instance
	self._flags = data.flags
	self._emoji = data.emoji and PartialEmoji(data.emoji)
	self._party = data.party and ActivityParty(data.party)
	self._assets = data.assets and ActivityAssets(data.assets)
	self._secrets = data.secrets and ActivitySecrets(data.secrets)
	self._timestamps = data.timestamps and ActivityTimestamps(data.timestamps)
	self._buttons = helpers.structs(ActivityButton, data.buttons)
end

function get:name()
	return self._name
end

function get:type()
	return self._type
end

function get:url()
	return self._url
end

function get:createdAt()
	return self._created_at
end

function get:timestamps()
	return self._timestamps
end

function get:applicationId()
	return self._application_id
end

function get:details()
	return self._details
end

function get:state()
	return self._state
end

function get:emoji()
	return self._emoji
end

function get:party()
	return self._party
end

function get:assets()
	return self._assets
end

function get:secrets()
	return self._secrets
end

function get:instance()
	return self._instance
end

function get:flags()
	return self._flags
end

function get:buttons()
	return self._buttons
end

return Activity
