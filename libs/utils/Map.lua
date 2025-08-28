local class = require('../class')
local typing = require('../typing')

local checkValue = typing.checkValue

local Map = class('Map')

function Map:__init()
	self._hash = {}
	self._prev = {}
	self._next = {}
	self._head = nil
	self._tail = nil
	self._size = 0
end

function Map:__len()
	return self._size
end

function Map:has(k)
	checkValue(k)
	return self._hash[k] ~= nil
end

function Map:get(k)
	checkValue(k)
	return self._hash[k]
end

function Map:set(k, v)
	checkValue(k)
	checkValue(v)
	if self._hash[k] == nil then
		if self._tail == nil then
			self._head = k
			self._tail = k
		else
			self._prev[k] = self._tail
			self._next[self._tail] = k
			self._tail = k
		end
		self._size = self._size + 1
	end
	self._hash[k] = v
end

function Map:delete(k)
	checkValue(k)
	if self._hash[k] == nil then return end
	local prv = self._prev[k]
	local nxt = self._next[k]
	if prv then
		self._next[prv] = nxt
	else
		self._head = nxt
	end
	if nxt then
		self._prev[nxt] = prv
	else
		self._tail = prv
	end
	self._hash[k] = nil
	self._prev[k] = nil
	self._next[k] = nil
	self._size = self._size - 1
end

function Map:getKeys()
	local keys = {}
	local k = self._head
	while k do
		keys[#keys + 1] = k
		k = self._next[k]
	end
	return keys
end

function Map:getValues()
	local values = {}
	local k = self._head
	while k do
		values[#values + 1] = self._hash[k]
		k = self._next[k]
	end
	return values
end

function Map:getEntries()
	local entries = {}
	local k = self._head
	while k do
		entries[#entries + 1] = {k, self._hash[k]}
		k = self._next[k]
	end
	return entries
end

return Map