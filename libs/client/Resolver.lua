local fs = require('fs')
local base64 = require('base64')
local class = require('class')
local http = require('coro-http')

local request = http.request
local readFileSync = fs.readFileSync
local classes = class.classes
local isInstance = class.isInstance
local insert = table.insert

local Resolver = {}

local function isSnowflake(n)
	if type(n) == 'string' then
		n = tonumber(n)
		return n and n % 1 == 0 and 0 <= n and n <= 2^64
	end
end

function Resolver.id(obj)
	if isSnowflake(obj) then
		return obj
	elseif isInstance(obj, classes.Snowflake) then
		return obj.id
	elseif isInstance(obj, classes.Member) then
		return obj.user.id
	end
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
	if type(obj) == 'string' then
		return obj
	elseif isInstance(obj, classes.Emoji) then
		return obj.name .. ':' .. obj.id
	elseif isInstance(obj, classes.Reaction) then
		local emoji = obj._emoji_name
		if obj._emoji_id then
			emoji = emoji .. ':' .. obj._emoji_id
		end
		return emoji
	end
end

function Resolver.number(obj) -- TODO: probably should have a BoxedValue class
	if tonumber(obj) then
		return obj
	elseif isInstance(obj, classes.Color) then
		return obj.value
	elseif isInstance(obj, classes.Permissions) then
		return obj.value
	end
end

function Resolver.boolean(obj)
	if type(obj) == 'boolean' then
		return obj
	else
		return false
	end
end

function Resolver.file(path)
	if path:find('https?://') == 1 then
		local success, res, data = pcall(request, 'GET', path)
		if not success then
			return nil, res
		elseif res.code > 299 then
			return nil, res.reason
		else
			return data
		end
	else
		return readFileSync(path)
	end
end

function Resolver.image(obj)
	if type(obj) == 'string' then
		if obj:find('data:.*;base64,') then
			return obj
		end
		local data = Resolver.readFile(obj)
		if data then
			return 'data:;base64,' .. base64.encode(data) -- TODO: test with gifs
		end
	end
end

return Resolver
