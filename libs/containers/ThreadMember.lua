--[=[
@c ThreadMember x Container
@d Represents a Discord Thread Member. Thread members hold extra information
regarding a member in the context of a thread, such as thread join date.
]=]

local Container = require('containers/abstract/Container')

local ThreadMember, get = require('class')('ThreadMember', Container)

-- this will be needed when inserting an instance into the cache
local function prepareData(data)
	data.id, data.thread_id = data.user_id, data.id or data.thread_id
end

function ThreadMember:__init(data, parent)
	prepareData(data)
	Container.__init(self, data, parent)
	self._guild = parent.guild
	return self:_loadMore(data)
end

function ThreadMember:_load(data)
	prepareData(data)
	Container._load(self, data)
	return self:_loadMore(data)
end

function ThreadMember:__hash()
	return self._user_id
end

function ThreadMember:_loadMore(data)
	if data.member then
		self._member = self._guild._members:_insert(data.member)
	end
end

--[=[
@m getGuildMember
@t http?
@r Member
@d Returns the guild Member this instance represent. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made.
]=]
function ThreadMember:getGuildMember()
	if self._member then
		return self._member
	end
	return self._guild:getMember(self._user_id)
end

--[=[
@m remove
@t http
@r boolean
@d Removes (kicks) this member from the thread.
]=]
function ThreadMember:remove()
	return self._parent:removeMember(self._user_id)
end

--[=[
@m canManage
@t http?
@r boolean/nil
@d Whether this member is able to manage the thread. If the guild member object is cached
no HTTP request will be made, otherwise it will be requested and a `nil` return will indicate error.
]=]
function ThreadMember:canManage()
	local member, err = self:getGuildMember()
	if not member then
		return nil, err
	end
	return self._parent:canManage(member)
end

--[=[
@m canSend
@t http?
@r boolean/nil
@d Whether this member is able to send messages in the thread. If the guild member object is cached
no HTTP request will be made, otherwise it will be requested and a `nil` return will indicate error.
]=]
function ThreadMember:canSend()
	local member, err = self:getGuildMember()
	if not member then
		return nil, err
	end
	return self._parent:canSend(member)
end

--[=[
@m canUnarchive
@t http?
@r boolean/nil
@d Whether this member is able to unarchive the thread. Returns `false` if the thread is not archived.
If the guild member object is cached no HTTP request will be made,
otherwise it will be requested and a `nil` return will indicate error.
]=]
function ThreadMember:canUnarchive()
	local member, err = self:getGuildMember()
	if not member then
		return nil, err
	end
	return self._parent:canUnarchive(member)
end

--[=[@p joinedAt string The time at which the member last joined the thread, represented as
an ISO 8601 string plus microseconds when available.]=]
function get.joinedAt(self)
	return self._join_timestamp
end

--[=[@p flags number Any thread channel specific configuration.]=]
function get.flags(self)
	return self._flags
end

--[=[@p thread GuildThreadChannel The thread this member is in.]=]
function get.thread(self)
	return self._parent
end

--[=[@p thread string The thread ID this member is in.]=]
function get.threadId(self)
	return self._thread_id
end

--[=[@p guildMember Member/nil The cached guild member instance this represents.]=]
function get.guildMember(self)
	return self._member
end

--[=[@p guildMember User/nil The cached user instance this represents.]=]
function get.user(self)
	return self._parent.client._users:get(self._user_id)
end

return ThreadMember
