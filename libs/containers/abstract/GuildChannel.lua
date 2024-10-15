--[=[
@c GuildChannel x Channel
@t abc
@d Defines the base methods and properties for all Discord guild channels.
]=]

local json = require('json')
local enums = require('enums')
local class = require('class')
local Channel = require('containers/abstract/Channel')
local PermissionOverwrite = require('containers/PermissionOverwrite')
local GuildThreadChannel = require('containers/GuildThreadChannel')
local Invite = require('containers/Invite')
local Cache = require('iterables/Cache')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')
local Time = require('utils/Time')

local isInstance = class.isInstance
local classes = class.classes
local channelType = assert(enums.channelType)

local insert, sort = table.insert, table.sort
local min, max, floor = math.min, math.max, math.floor
local huge = math.huge

local GuildChannel, get = class('GuildChannel', Channel)

function GuildChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self.client._channel_map[self._id] = parent
	self._permission_overwrites = Cache({}, PermissionOverwrite, self)
	self._thread_channels = SecondaryCache(GuildThreadChannel, self._parent._thread_channels)
	return self:_loadMore(data)
end

function GuildChannel:_load(data)
	Channel._load(self, data)
	return self:_loadMore(data)
end

function GuildChannel:_loadMore(data)
	return self._permission_overwrites:_load(data.permission_overwrites, true)
end

--[=[
@m setName
@t http
@p name string
@r boolean
@d Sets the channel's name. This must be between 2 and 100 characters in length.
]=]
function GuildChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setCategory
@t http
@p id Channel-ID-Resolvable
@r boolean
@d Sets the channel's parent category.
]=]
function GuildChannel:setCategory(id)
	id = Resolver.channelId(id)
	return self:_modify({parent_id = id or json.null})
end

local function sorter(a, b)
	if a.position == b.position then
		return tonumber(a.id) < tonumber(b.id)
	else
		return a.position < b.position
	end
end

local function getSortedChannels(self)

	local channels
	local t = self._type
	if t == channelType.text or t == channelType.news then
		channels = self._parent._text_channels
	elseif t == channelType.voice then
		channels = self._parent._voice_channels
	elseif t == channelType.category then
		channels = self._parent._categories
	end

	local ret = {}
	for channel in channels:iter() do
		insert(ret, {id = channel._id, position = channel._position})
	end
	sort(ret, sorter)

	return ret

end

local function setSortedChannels(self, channels)
	local data, err = self.client._api:modifyGuildChannelPositions(self._parent._id, channels)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m moveUp
@t http
@p n number
@r boolean
@d Moves a channel up its list. The parameter `n` indicates how many spaces the
channel should be moved, clamped to the highest position, with a default of 1 if
it is omitted. This will also normalize the positions of all channels.
]=]
function GuildChannel:moveUp(n)

	n = tonumber(n) or 1
	if n < 0 then
		return self:moveDown(-n)
	end

	local channels = getSortedChannels(self)

	local new = huge
	for i = #channels - 1, 0, -1 do
		local v = channels[i + 1]
		if v.id == self._id then
			new = max(0, i - floor(n))
			v.position = new
		elseif i >= new then
			v.position = i + 1
		else
			v.position = i
		end
	end

	return setSortedChannels(self, channels)

end

--[=[
@m moveDown
@t http
@p n number
@r boolean
@d Moves a channel down its list. The parameter `n` indicates how many spaces the
channel should be moved, clamped to the lowest position, with a default of 1 if
it is omitted. This will also normalize the positions of all channels.
]=]
function GuildChannel:moveDown(n)

	n = tonumber(n) or 1
	if n < 0 then
		return self:moveUp(-n)
	end

	local channels = getSortedChannels(self)

	local new = -huge
	for i = 0, #channels - 1 do
		local v = channels[i + 1]
		if v.id == self._id then
			new = min(i + floor(n), #channels - 1)
			v.position = new
		elseif i <= new then
			v.position = i - 1
		else
			v.position = i
		end
	end

	return setSortedChannels(self, channels)

end

--[=[
@m createInvite
@t http
@op payload table
@r Invite
@d Creates an invite to the channel. Optional payload fields are: max_age: number
time in seconds until expiration, default = 86400 (24 hours), max_uses: number
total number of uses allowed, default = 0 (unlimited), temporary: boolean whether
the invite grants temporary membership, default = false, unique: boolean whether
a unique code should be guaranteed, default = false
]=]
function GuildChannel:createInvite(payload)
	local data, err = self.client._api:createChannelInvite(self._id, payload)
	if data then
		return Invite(data, self.client)
	else
		return nil, err
	end
end

--[=[
@m getInvites
@t http
@r Cache
@d Returns a newly constructed cache of all invite objects for the channel. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]=]
function GuildChannel:getInvites()
	local data, err = self.client._api:getChannelInvites(self._id)
	if data then
		return Cache(data, Invite, self.client)
	else
		return nil, err
	end
end

--[=[
@m getPermissionOverwriteFor
@t mem
@p obj Role/Member
@r PermissionOverwrite
@d Returns a permission overwrite object corresponding to the provided member or
role object. If a cached overwrite is not found, an empty overwrite with
zero-permissions is returned instead. Therefore, this can be used to create a
new overwrite when one does not exist. Note that the member or role must exist
in the same guild as the channel does.
]=]
function GuildChannel:getPermissionOverwriteFor(obj)
	local id, type
	if isInstance(obj, classes.Role) and self._parent == obj._parent then
		id, type = obj._id, 'role'
	elseif isInstance(obj, classes.Member) and self._parent == obj._parent then
		id, type = obj._user._id, 'member'
	else
		return nil, 'Invalid Role or Member: ' .. tostring(obj)
	end
	local overwrites = self._permission_overwrites
	return overwrites:get(id) or overwrites:_insert(setmetatable({
		id = id, type = type, allow = 0, deny = 0
	}, {__jsontype = 'object'}))
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the channel. This cannot be undone!
]=]
function GuildChannel:delete()
	return self:_delete()
end

--[=[
@m setDefaultAutoArchiveDuration
@t http
@p duration Time/number
@r boolean
@d Sets the current default duration after which Discord considers a thread created under this
channel to be inactive. This is only a default value and individual threads may have a different value.

Possible durations are `60` (1 hour), `1440` (1 day), `4320` (7 days).
]=]
function GuildChannel:setDefaultAutoArchiveDuration(duration)
  if isInstance(duration, Time) then
		duration = duration:toMinutes()
	end
  return self:_modify({default_auto_archive_duration = duration})
end

--[=[
@m startThread
@t http
@p channelData string/table
@op message Message-ID-Resolvable
@r GuildThreadChannel
@d Create a new thread under this channel.
To create a private thread set `channelData.type` to `channelType.privateThread`.
]=]
function GuildChannel:startThread(channelData, message)
	channelData = type(channelData) == 'string' and {name = channelData} or channelData
	if not channelData.type then
		-- future proofing; Discord will start requiring this field in the future
		channelData.type = channelType.publicThread
	end
	message = Resolver.messageId(message)
	local data, err
	if message then
		data, err = self.client._api:startThreadWithMessage(self._id, message, channelData)
	else
		data, err = self.client._api:startThreadWithoutMessage(self._id, channelData)
	end
	if data then
		return self._thread_channels:_insert(data, self)
	else
		return nil, err
	end
end

local function getArchivedThreads(channel, req, limit, before)
  local data, err = req(channel.client._api, channel._id, {
    limit = limit,
    before = before,
  })
  if data then
    local cache = SecondaryCache(data.threads, channel._thread_channels, channel)
		for _, member in ipairs(data.members) do
			local thread = cache:get(member.id)
			thread:_loadMember(member)
		end
		return cache, data.has_more or false
  else
    return nil, err
  end
end

--[=[
@m getArchivedPublicThreads
@t http
@op limit number
@op before ISO-Timestamp-Resolvable
@r SecondaryCache
@r boolean
@d Returns an iterable cache of public archived threads under this channel.
]=]
function GuildChannel:getArchivedPublicThreads(limit, before)
  before = Resolver.isoTimestamp(before)
	return getArchivedThreads(self, self.client._api.listArchivedPublicThreads, limit, before)
end

--[=[
@m getArchivedPrivateThreads
@t http
@op limit number
@op before ISO-Timestamp-Resolvable
@r SecondaryCache
@r boolean
@d Returns an iterable cache of private archived threads under this channel.
]=]
function GuildChannel:getArchivedPrivateThreads(limit, before)
  before = Resolver.isoTimestamp(before)
	return getArchivedThreads(self, self.client._api.listArchivedPrivateThreads, limit, before)
end

--[=[
@m getJoinedArchivedPrivateThreads
@t http
@op limit number
@op before Channel-ID-Resolvable
@r SecondaryCache
@r boolean
@d Returns an iterable cache of private archived threads that the current user has joined under this channel.
]=]
function GuildChannel:getJoinedArchivedPrivateThreads(limit, before)
	before = Resolver.channelId(before)
	return getArchivedThreads(self, self.client._api.listJoinedArchivedPrivateThreads, limit, before)
end

--[=[@p permissionOverwrites Cache An iterable cache of all overwrites that exist in this channel. To access an
overwrite that may exist, but is not cached, use `GuildChannel:getPermissionOverwriteFor`.]=]
function get.permissionOverwrites(self)
	return self._permission_overwrites
end

--[=[@p name string The name of the channel. This should be between 2 and 100 characters in length.]=]
function get.name(self)
	return self._name
end

--[=[@p position number The position of the channel, where 0 is the highest.]=]
function get.position(self)
	return self._position
end

--[=[@p guild Guild The guild in which this channel exists.]=]
function get.guild(self)
	return self._parent
end

--[=[@p category GuildCategoryChannel/nil The parent channel category that may contain this channel.]=]
function get.category(self)
	return self._parent._categories:get(self._parent_id)
end

--[=[@p private boolean Whether the "everyone" role has permission to view this
channel. In the Discord channel, private text channels are indicated with a lock
icon and private voice channels are not visible.]=]
function get.private(self)
	local overwrite = self._permission_overwrites:get(self._parent._id)
	return overwrite and overwrite:getDeniedPermissions():has('readMessages')
end

function get.threads(self)
	return self._thread_channels
end

--[=[@p defaultAutoArchiveDuration number/nil The current default duration after which Discord considers
a thread created under this channel to be inactive. This is only a default value and individual threads
may have a different value.]=]
function get.defaultAutoArchiveDuration(self)
	return self._default_auto_archive_duration
end

return GuildChannel
