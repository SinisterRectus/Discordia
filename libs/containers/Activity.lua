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

function get.start(self)
	return self._start
end

function get.stop(self)
	return self._stop
end

function get.name(self)
	return self._name
end

function get.type(self)
	return self._type
end

function get.url(self)
	return self._url
end

function get.applicationId(self)
	return self._application_id
end

function get.state(self)
	return self._state
end

function get.details(self)
	return self._details
end

function get.textSmall(self)
	return self._small_text
end

function get.textLarge(self)
	return self._large_text
end

function get.imageSmall(self)
	return self._small_image
end

function get.imageLarge(self)
	return self._large_image
end

function get.partyId(self)
	return self._party_id
end

function get.partySize(self)
	return self._party_size
end

function get.partyMax(self)
	return self._party_max
end

return Activity
