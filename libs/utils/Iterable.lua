local class = require('../class')
local typing = require('typing')

local insert, sort = table.insert, table.sort
local checkType, checkCallable = typing.checkType, typing.checkCallable

local Iterable = class('Iterable')

function Iterable:__init(arr, key, sorter)
	self._arr = arr and checkType('table', arr) or {}
	self._key = key and checkType('string', key) or nil
	if sorter then
		self._sorter = checkCallable(sorter)
		sort(arr, sorter)
	else
		self._sorter = nil
	end
end

function Iterable:__len()
	return #self._arr
end

function Iterable:__pairs()
	local i = 0
	local arr = self._arr
	if self._key then
		local k = self._key
		return function()
			i = i + 1
			local v = arr[i]
			if v then
				return v[k], v
			end
		end
	else
		return self:__ipairs()
	end
end

function Iterable:__ipairs()
	local i = 0
	local arr = self._arr
	return function()
		i = i + 1
		local v = arr[i]
		if v then
			return i, v
		end
	end
end

function Iterable:get(k)
	local t = type(k)
	if t == 'string' then
		if not self._key then
			return error('key must be a number', 2)
		end
		for _, v in ipairs(self._arr) do
			if v[self._key] == k then
				return v
			end
		end
	elseif t == 'number' then
		return self._arr[k]
	else
		return error('key must be a string or number', 2)
	end
end

function Iterable:sort(sorter)
	self._sorter = checkCallable(sorter)
	sort(self._arr, sorter)
end

function Iterable:iter()
	local i = 0
	local arr = self._arr
	return function()
		i = i + 1
		return arr[i]
	end
end

function Iterable:filter(fn)
	checkCallable(fn)
	local new = {}
	for _, v in ipairs(self._arr) do
		if fn(v) then
			insert(new, v)
		end
	end
	return Iterable(new, self._key, self._sorter)
end

function Iterable:count(fn)
	checkCallable(fn)
	local n = 0
	for _, v in ipairs(self._arr) do
		if fn(v) then
			n = n + 1
		end
	end
	return n
end

function Iterable:find(fn)
	checkCallable(fn)
	for _, v in ipairs(self._arr) do
		if fn(v) then
			return v
		end
	end
end

function Iterable:forEach(fn)
	checkCallable(fn)
	for _, v in ipairs(self._arr) do
		fn(v)
	end
end

function Iterable:toArray()
	local ret = {}
	for _, v in ipairs(self._arr) do
		insert(ret, v)
	end
	return ret
end

function Iterable:toTable()
	if self._key then
		local ret = {}
		for _, v in ipairs(self._arr) do
			ret[v[self._key]] = v
		end
		return ret
	else
		return self:toArray()
	end
end

function Iterable:random()
	return self._arr[math.random(#self._arr)]
end

function Iterable:copy()
	local new = {}
	for _, v in ipairs(self._arr) do
		insert(new, v)
	end
	return Iterable(new, self._key, self._sorter)
end

function Iterable:select(...)
	local rows = {}
	local keys, n = {...}, select('#', ...)
	for _, v in ipairs(self._arr) do
		local row = {}
		for i = 1, n do
			row[i] = v[keys[i]]
		end
		insert(rows, row)
	end
	return rows
end

return Iterable
