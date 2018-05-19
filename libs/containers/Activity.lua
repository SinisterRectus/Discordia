--[=[
@c Activity
@d description
]=]

local Container = require('containers/abstract/Container')

local Activity, get = require('class')('Activity')

function Activity:__init(data, parent)
	Container.__init(self, data, parent)
	return self:_loadMore(data)
end

function Activity:_load(data)
	Container._load(self, data)
	return self:_loadMore(data)
end

function Activity:_loadMore(data)
	local timestamps = data.timestamps
	self._start = timestamps and timestamps.start
	self._stop = timestamps and timestamps['end'] -- thanks discord
	local assets = data.assets
	self._small_text = assets and assets.small_text
	self._large_text = assets and assets.large_text
	self._small_image = assets and assets.small_image
	self._large_image = assets and assets.large_image
	local party = data.party
	self._party_id = party and party.id
	self._party_size = party and party.size and party.size[1]
	self._party_max = party and party.size and party.size[2]
end

--[=[@p start number|nil description]=]
function get.start(self)
	return self._start
end

--[=[@p stop number|nil description]=]
function get.stop(self)
	return self._stop
end

--[=[@p name string|nil description]=]
function get.name(self)
	return self._name
end

--[=[@p type number|nil description]=]
function get.type(self)
	return self._type
end

--[=[@p url string|nil description]=]
function get.url(self)
	return self._url
end

--[=[@p applicationId string description]=]
function get.applicationId(self)
	return self._application_id
end

--[=[@p state string|nil description]=]
function get.state(self)
	return self._state
end

--[=[@p details string|nil description]=]
function get.details(self)
	return self._details
end

--[=[@p textSmall string|nil description]=]
function get.textSmall(self)
	return self._small_text
end

--[=[@p textLarge string|nil description]=]
function get.textLarge(self)
	return self._large_text
end

--[=[@p imageSmall string|nil description]=]
function get.imageSmall(self)
	return self._small_image
end

--[=[@p imageLarge string|nil description]=]
function get.imageLarge(self)
	return self._large_image
end

--[=[@p partyId string|nil description]=]
function get.partyId(self)
	return self._party_id
end

--[=[@p partySize number|nil description]=]
function get.partySize(self)
	return self._party_size
end

--[=[@p partyMax number|nil description]=]
function get.partyMax(self)
	return self._party_max
end

return Activity
