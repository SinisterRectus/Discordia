local fs = require('fs')
local base64 = require('base64')
local class = require('class')
local http = require('coro-http')

local request = http.request
local encode = base64.encode
local readFileSync = fs.readFileSync
local classes = class.classes
local isInstance = class.isInstance
local insert = table.insert
local running = coroutine.running

local Resolver = {}

function Resolver.id(obj)
	if type(obj) == 'string' then
		local n = tonumber(obj)
		if n and n % 1 == 0 and 0 <= n and n <= 2^64 then
			return obj
		end
	elseif isInstance(obj, classes.Snowflake) then
		return obj.id
	elseif isInstance(obj, classes.Member) then
		return obj.user.id
	end
	return nil
end

function Resolver.ids(objs)
	local ret = {}
	if isInstance(objs, classes.Iterable) then
		for obj in objs:iter() do
			insert(ret, Resolver.id(obj))
		end
	elseif type(objs) == 'table' then
		for _, obj in pairs(objs) do
			insert(ret, Resolver.id(obj))
		end
	end
	return ret
end

function Resolver.emoji(obj)
	if isInstance(obj, classes.Emoji) then
		return obj.name .. ':' .. obj.id
	elseif isInstance(obj, classes.Reaction) then
		if obj._emoji_id then
			return obj._emoji_name .. ':' .. obj._emoji_id
		else
			return obj._emoji_name
		end
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

function Resolver.file(path)
	if path:find('https?://') == 1 then
		local _, main = running()
		if main then
			return nil, 'Cannot fetch URL outside of a coroutine'
		end
		local success, res, data = pcall(request, 'GET', path)
		if not success then
			return nil, res
		elseif res.code > 299 then
			return nil, res.reason
		else
			return data
		end
	end
	return readFileSync(path)
end

function Resolver.base64(obj)
	if type(obj) == 'string' then
		if obj:find('data:.*;base64,') == 1 then
			return obj
		end
		local data, err = Resolver.file(obj)
		if not data then
			return nil, err
		end
		return 'data:;base64,' .. encode(data)
	end
	return nil
end

return Resolver
