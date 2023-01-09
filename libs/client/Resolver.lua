local fs = require('fs')
local ffi = require('ffi')
local ssl = require('openssl')
local class = require('class')
local enums = require('enums')

local permission = assert(enums.permission)
local gatewayIntent = assert(enums.gatewayIntent)
local actionType = assert(enums.actionType)
local messageFlag = assert(enums.messageFlag)
local base64 = ssl.base64
local readFileSync = fs.readFileSync
local classes = class.classes
local isInstance = class.isInstance
local isObject = class.isObject
local insert = table.insert
local format = string.format

local Resolver = {}

local istype = ffi.istype
local int64_t = ffi.typeof('int64_t')
local uint64_t = ffi.typeof('uint64_t')

local function int(obj)
	local t = type(obj)
	if t == 'string' then
		if tonumber(obj) then
			return obj
		end
	elseif t == 'cdata' then
		if istype(int64_t, obj) or istype(uint64_t, obj) then
			return tostring(obj):match('%d*')
		end
	elseif t == 'number' then
		return format('%i', obj)
	elseif isInstance(obj, classes.Date) then
		return obj:toSnowflake()
	end
end

function Resolver.userId(obj)
	if isObject(obj) then
		if isInstance(obj, classes.User) then
			return obj.id
		elseif isInstance(obj, classes.Member) then
			return obj.user.id
		elseif isInstance(obj, classes.Message) then
			return obj.author.id
		elseif isInstance(obj, classes.Guild) then
			return obj.ownerId
		end
	end
	return int(obj)
end

function Resolver.messageId(obj)
	if isInstance(obj, classes.Message) then
		return obj.id
	end
	return int(obj)
end

function Resolver.channelId(obj)
	if isInstance(obj, classes.Channel) then
		return obj.id
	end
	return int(obj)
end

function Resolver.roleId(obj)
	if isInstance(obj, classes.Role) then
		return obj.id
	end
	return int(obj)
end

function Resolver.emojiId(obj)
	if isInstance(obj, classes.Emoji) then
		return obj.id
	elseif isInstance(obj, classes.Reaction) then
		return obj.emojiId
	elseif isInstance(obj, classes.Activity) then
		return obj.emojiId
	end
	return int(obj)
end

function Resolver.guildId(obj)
	if isInstance(obj, classes.Guild) then
		return obj.id
	end
	return int(obj)
end

function Resolver.entryId(obj)
	if isInstance(obj, classes.AuditLogEntry) then
		return obj.id
	end
	return int(obj)
end

function Resolver.messageIds(objs)
	local ret = {}
	if isInstance(objs, classes.Iterable) then
		for obj in objs:iter() do
			insert(ret, Resolver.messageId(obj))
		end
	elseif type(objs) == 'table' then
		for _, obj in pairs(objs) do
			insert(ret, Resolver.messageId(obj))
		end
	end
	return ret
end

function Resolver.roleIds(objs)
	local ret = {}
	if isInstance(objs, classes.Iterable) then
		for obj in objs:iter() do
			insert(ret, Resolver.roleId(obj))
		end
	elseif type(objs) == 'table' then
		for _, obj in pairs(objs) do
			insert(ret, Resolver.roleId(obj))
		end
	end
	return ret
end

function Resolver.emoji(obj)
	if isInstance(obj, classes.Emoji) then
		return obj.hash
	elseif isInstance(obj, classes.Reaction) then
		return obj.emojiHash
	elseif isInstance(obj, classes.Activity) then
		return obj.emojiHash
	end
	return tostring(obj)
end

function Resolver.color(obj)
	if isInstance(obj, classes.Color) then
		return obj.value
	end
	return tonumber(obj)
end

function Resolver.permissions(obj)
	if isInstance(obj, classes.Permissions) then
		return obj.value
	end
	return tonumber(obj)
end

function Resolver.permission(obj)
	local t = type(obj)
	local n = nil
	if t == 'string' then
		n = permission[obj]
	elseif t == 'number' then
		n = permission(obj) and obj
	end
	return n
end

function Resolver.gatewayIntent(obj)
	local t = type(obj)
	local n = nil
	if t == 'string' then
		n = gatewayIntent[obj]
	elseif t == 'number' then
		n = gatewayIntent(obj) and obj
	end
	return n
end

function Resolver.actionType(obj)
	local t = type(obj)
	local n = nil
	if t == 'string' then
		n = actionType[obj]
	elseif t == 'number' then
		n = actionType(obj) and obj
	end
	return n
end

function Resolver.messageFlag(obj)
	local t = type(obj)
	local n = nil
	if t == 'string' then
		n = messageFlag[obj]
	elseif t == 'number' then
		n = messageFlag(obj) and obj
	end
	return n
end

function Resolver.base64(obj)
	if type(obj) == 'string' then
		if obj:find('data:.*;base64,') == 1 then
			return obj
		end
		local data, err = readFileSync(obj)
		if not data then
			return nil, err
		end
		return 'data:;base64,' .. base64(data)
	end
	return nil
end

return Resolver
