--[=[
@c GuildThreadChannel x TextChannel
@d Represents a Discord thread channel. Essentially a temporary sub-channel
inside an existing channel.
]=]

local enums = require('enums')
local class = require('class')
local Resolver = require('client/Resolver')
local TextChannel = require('containers/abstract/TextChannel')
local ThreadMember = require('containers/ThreadMember')
local Cache = require('iterables/Cache')
local SecondaryCache = require('iterables/SecondaryCache')
local Date = require('utils/Date')
local Time = require('utils/Time')

local isInstance = class.isInstance
local channelType = assert(enums.channelType)
local channelFlag = assert(enums.channelFlag)
local permission = assert(enums.permission)
local band, bor, bnot = bit.band, bit.bor, bit.bnot

local GuildThreadChannel, get = class('GuildThreadChannel', TextChannel)

-- discord, in all of their wisdom, decided that ThreadMember.id is actually the channel id!
-- this makes sure we use the unique user ID for caching instead of channel id
local function threadMemberHash(data)
	return data.user_id
end

function GuildThreadChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self.client._channel_map[self._id] = parent._parent
	self._members = Cache({}, ThreadMember, self)
	self._members._hash = threadMemberHash -- default to user_id instead of id
	self._thread_metadata = {}
	return self:_loadMore(data)
end

function GuildThreadChannel:_load(data)
	TextChannel._load(self, data)
	return self:_loadMore(data)
end

function GuildThreadChannel:_loadMember(member)
	if not member.id then
		member.id = self._id
		member.user_id = self.client.user.id
	end
	self._member = self._members:_insert(member)
end

function GuildThreadChannel:_loadMore(data)
	if data.member then
		self:_loadMember(data.member)
	end
	if data.thread_metadata then
		self._thread_metadata = data.thread_metadata
	end
end

--[=[
@m getThreadMember
@t http?
@p id User-ID-Resolvable
@r ThreadMember
@d Gets the Thread Member object of a joined member by ID. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made.
]=]
function GuildThreadChannel:getThreadMember(id)
	id = Resolver.userId(id)
	local member = self._members:get(id)
	if member then
		return member
	end
	local data, err = self.client._api:getThreadMember(self._id, id)
	if data then
		return self._members:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m getThreadMember
@t http
@op limit number
@op afterId User-ID-Resolvable
@r SecondaryCache
@d Gets the list of currently joined members. If `afterID` is provided, only the users joined after the specified ID will be returned.

This will also update the cache of currently loaded members, and while the cache
will never automatically gain or lose objects, the objects that it contains may be updated by gateway events.
]=]
function GuildThreadChannel:getThreadMembers(limit, afterId)
	afterId = Resolver.userId(afterId)
	local data, err = self.client._api:getThreadMembers(self._id, {
		with_member = true, -- will be required on API v11
		limit = limit,
		after_id = afterId,
	})
	if data then
		return SecondaryCache(data, self._members)
	else
		return nil, err
	end
end

--[=[
@m getCurrentMember
@t http?
@r ThreadMember
@d Gets the current user's ThreadMember object, if currently joined. 
]=]
function GuildThreadChannel:getCurrentMember()
	local member, err = self:getThreadMember(self._user_id)
	if member then
		self._member = member
		return member
	end
	return nil, err
end

--[=[
@m getThreadOwner
@t http?
@r ThreadMember
@d Gets the ThreadMember who created this thread.
Equivalent to `GuildThreadChannel:getThreadMember(self.ownerId)`.
]=]
function GuildThreadChannel:getThreadOwner()
	return self:getThreadMember(self._owner_id)
end

--[=[
@m getStarterMessage
@t http?
@r Message
@d Gets the message object this thread started with. Not all threads has a starter message,
in which case be prepared to handle 404 errors.
]=]
function GuildThreadChannel:getStarterMessage()
	return self._parent:getMessage(self._id) -- thread's id is the starter message id
end

--[=[
@m join
@t http
@r boolean
@d Join this thread channel.
]=]
function GuildThreadChannel:join()
	local success, err = self.client._api:joinThread(self._id)
	if success then
		return true
	else
		return false, err
	end
end

--[=[
@m leave
@t http
@r boolean
@d Leave this thread channel.
]=]
function GuildThreadChannel:leave()
	local success, err = self.client._api:leaveThread(self._id)
	if success then
		return true
	else
		return false, err
	end
end

--[=[
@m addMember
@t http
@p id User-ID-Resolvable
@r boolean
@d Adds a member into thread by ID.
]=]
function GuildThreadChannel:addMember(id)
	id = Resolver.userId(id)
	local success, err = self.client._api:addThreadMember(self._id, id)
	if success then
		return true
	else
		return false, err
	end
end

--[=[
@m removeMember
@t http
@p id User-ID-Resolvable
@r boolean
@d Removes (kicks) a member from a thread by ID.
]=]
function GuildThreadChannel:removeMember(id)
	id = Resolver.userId(id)
	local success, err = self.client._api:removeThreadMember(self._id, id)
	if success then
		return true
	else
		return false, err
	end
end

--[=[
@m archive
@t http
@r boolean
@d Archive this thread.
]=]
function GuildThreadChannel:archive()
	return self:_modify({archived = true})
end

--[=[
@m unarchive
@t http
@r boolean
@d Unarchive this thread, if the thread is locked you need sufficient permissions.
]=]
function GuildThreadChannel:unarchive()
	return self:_modify({archived = false})
end

--[=[
@m lock
@t http
@r boolean
@d Lock this thread, to prevent non-moderator members from un-archiving it.
Requires `permission.manageThreads` or higher permissions.
]=]
function GuildThreadChannel:lock()
	return self:_modify({locked = true})
end

--[=[
@m unlock
@t http
@r boolean
@d Unlock this thread, allowing its members to unarchive it.
Requires `permission.manageThreads` or higher permissions.
]=]
function GuildThreadChannel:unlock()
	return self:_modify({locked = false})
end

--[=[
@m pin
@t http
@r boolean
@d Pin this thread in the forum channel. Only relevant for forum channel threads.
]=]
function GuildThreadChannel:pin()
	return self:_modify({flags = bor(self._flags or 0, channelFlag.pinned)})
end

--[=[
@m unpin
@t http
@r boolean
@d Pin this thread in the forum channel. Only relevant for forum channel threads.
]=]
function GuildThreadChannel:unpin()
	return self:_modify({flags = band(self._flags or 0, bnot(channelFlag.pinned))})
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the thread. This cannot be undone!
]=]
function GuildThreadChannel:delete()
	return self:_delete()
end

--[=[
@m setAutoArchiveDuration
@t http
@p duration Time/number
@r boolean
@d Sets the duration after which Discord will automatically archive the thread if it becomes inactive, in minutes.
Possible durations are `60` (1 hour), `1440` (1 day), `4320` (7 days).
]=]
function GuildThreadChannel:setAutoArchiveDuration(duration)
	if isInstance(duration, Time) then
		duration = duration:toMinutes()
	end
	return self:_modify({auto_archive_duration = duration})
end

--[=[
@m setInvitable
@t http
@op invitable boolean
@r boolean
@d Sets the ability for non-moderator users to invite others into a private thread by mentioning them.
`invitable` defaults to `true`.
]=]
function GuildThreadChannel:setInvitable(invitable)
	invitable = invitable == nil and true or invitable
	return self:_modify({invitable = invitable})
end

-- TODO: this will probably require explicit ForumChannel support
-- function GuildThreadChannel:setAppliesTags(tags)
-- 	return self:_modify({applied_tags = tags or json.null})
-- end

--[=[
@m hasFlag
@t mem
@p flag Channel-Flag-Resolvable
@r boolean
@d Indicates whether the thread has a particular flag set.
]=]
function GuildThreadChannel:hasFlag(flag)
	flag = Resolver.channelFlag(flag)
	return band(self._flags or 0, flag) > 0
end

--[=[
@m canSend
@t http?
@op member Member
@r boolean/nil
@d Whether the provided member is able of sending messages in this thread.
Defaults to `GuildThreadChannel.member`.
]=]
function GuildThreadChannel:canSend(member)
	member = member or (self._member and self._member.member)
	if not member then
		local err
		member, err = self.guild:getMember(self.client.user.id)
		if not member then
			return nil, err
		end
	end
	local permissions = member:getPermissions(self._parent)
	if permissions:has(permission.administrator) then
		return true
	end
	local can_manage = self:canManage(member)
	-- we can't send if the thread is archived and locked and we can't manage it 
	if not can_manage and self.archived and self.locked then
		return false
	end
	-- we can't send if the thread is private, and we cannot manage it or join it
	if self.isPrivate and not (self.joined and can_manage) then
		return false
	end
	-- we can't send if the member is timed out
	if member.timedOut then
		return false
	end
	return member:hasPermission(permission.sendMessagesInThreads)
end

--[=[
@m canManage
@t http?
@op member Member
@r boolean/nil
@d Whether the provided Member is able to manage this thread.
Defaults to `GuildThreadChannel.member`.
]=]
function GuildThreadChannel:canManage(member)
	member = member or (self._member and self._member.member)
	if not member then
		local err
		member, err = self.guild:getMember(self.client.user.id)
		if not member then
			return nil, err
		end
	end
	local permissions = member:getPermissions(self._parent)
	if permissions:has(permission.administrator) then
		return true
	end
	return not member.timedOut and permissions:has(permission.manageThreads)
end

--[=[
@m canUnarchive
@t http?
@op member Member
@r boolean/nil
@d Whether the provided Member is able to unarchive this thread.
Defaults to `GuildThreadChannel.member`.
]=]
function GuildThreadChannel:canUnarchive(member)
	member = member or (self._member and self._member.member)
	if not member then
		local err
		member, err = self.guild:getMember(self.client.user.id)
		if not member then
			return nil, err
		end
	end
	if not self.archived then
		return false
	end
	return self:canSend(member) and (not self.locked or self:canManage(member))
end

--[=[@p memberCount number Approximately how many member is currently joined. Stops counting at 50.]=]
function get.memberCount(self)
	return self._member_count
end

--[=[@p messageCount number The number of sent messages in this thread, excluding starter message and deleted messages.]=]
function get.messageCount(self)
	return self._message_count
end

--[=[@p totalMessageSent number The number of sent messages in this thread, including deleted messages. Excludes starter message.]=]
function get.totalMessageSent(self)
	return self._total_message_sent
end

--[=[@p archived boolean Whether this thread is archived.]=]
function get.archived(self)
	return self._thread_metadata.archived
end

--[=[@p archivedAt string The ISO 8601 timestamp for when this thread got last archived.]=]
function get.archivedAt(self)
	return self._thread_metadata.archive_timestamp
end

--[=[@p archivedAtDate Date The Date for when this thread got last archived.

Equivalent to `Date.fromISO(GuildThreadChannel.archivedAt)`.
]=]
function get.archivedAtDate(self)
	return Date.fromISO(self._thread_metadata.archive_timestamp)
end

--[=[@p createdAt Date/nil The ISO 8601 timestamp for when the thread was created.
Only provided for threads created after 2022-01-09.]=]
function get.createdAt(self)
	return self._thread_metadata.create_timestamp
end

--[=[@p createdAtDate Date/nil The Date for when the thread was created.
Only provided for threads created after 2022-01-09.

Equivalent to `Date.fromISO(GuildThreadChannel.createdAt)`.
]=]
function get.createdAtDate(self)
	if self._thread_metadata.create_timestamp then
		return Date.fromISO(self._thread_metadata.create_timestamp)
	end
end

--[=[@p autoArchiveDuration number The duration of inactivity in minutes after which the thread will be archived.]=]
function get.autoArchiveDuration(self)
	return self._thread_metadata.auto_archive_duration or self._parent._default_auto_archive_duration
end

--[=[@p locked boolean Whether the thread is currently locked.]=]
function get.locked(self)
	return self._thread_metadata.locked
end

--[=[@p invitable Whether non-moderators can add other non-moderators to a thread.
Only relevant for private threads, always returns true for public threads.]=]
function get.invitable(self)
	local val = self._thread_metadata.invitable
	if not self.isPrivate and not val then
		val = true
	end
	return val
end

--[=[@p pinned boolean Whether the thread is pinned.
Only relevant for Forum Threads.]=]
function get.pinned(self)
	return self:hasFlag(channelFlag.pinned)
end

--[=[@p joined boolean Whether the current user has joined the thread.]=]
function get.joined(self)
	return not not self._members:get(self.client.user.id)
end

--[=[@p isPrivate boolean Whether the thread is a private thread.]=]
function get.isPrivate(self)
	return self._type == channelType.privateThread
end

--[=[@p nsfw boolean Whether the parent channel is marked as NSFW (not safe for work).]=]
function get.nsfw(self)
	return self._parent._nsfw or false
end

--[=[@p guild Guild The guild the thread channel is in.]=]
function get.guild(self)
	return self._parent._parent
end

--[=[@p me ThreadMember/nil The ThreadMember object of the current user.
Only available if the current user has joined the thread channel.

Equivalent to GuildThreadChannel.members:get(client.user.id).]=]
function get.me(self)
	return self._member
end

--[=[@p owner ThreadMember/nil The cached ThreadMember object of the thread owner.

Equivalent to GuildThreadChannel.members:get(self.ownerId).]=]
function get.owner(self)
	return self._members:get(self._owner_id)
end

--[=[@p ownerId string The ID of the user who created this thread and owns it.]=]
function get.ownerId(self)
	return self._owner_id
end

--[=[@p members Cache An iterable cache of all Thread Members currently loaded in memory.]=]
function get.members(self)
	return self._members
end

--[=[@p name string The thread channel name.]=]
function get.name(self)
	return self._name
end

--[=[@p parent TextChannel The channel object this thread is created under.]=]
function get.parent(self)
	return self._parent
end

return GuildThreadChannel
