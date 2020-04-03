local json = require('json')
local miniz = require('miniz')
local Mutex = require('utils/Mutex')
local Emitter = require('utils/Emitter')
local Stopwatch = require('utils/Stopwatch')

local websocket = require('coro-websocket')
local constants = require('constants')

local inflate = miniz.inflate
local encode, decode, null = json.encode, json.decode, json.null
local ws_parseUrl, ws_connect = websocket.parseUrl, websocket.connect

local GATEWAY_DELAY = constants.GATEWAY_DELAY

local TEXT   = 1
local BINARY = 2
local CLOSE  = 8

local function connect(url, path)
	local options = assert(ws_parseUrl(url))
	options.pathname = path
	return assert(ws_connect(options))
end

local WebSocket = require('class')('WebSocket', Emitter)

function WebSocket:__init(parent)
	Emitter.__init(self)
	self._parent = parent
	self._mutex = Mutex()
	self._sw = Stopwatch()
end

function WebSocket:connect(url, path)

	local success, res, read, write = pcall(connect, url, path)

	if success then
		self._read = read
		self._write = write
		self._reconnect = nil
		self:info('Connected to %s', url)
		local parent = self._parent
		for message in self._read do
			local payload, str = self:parseMessage(message)
			if not payload then break end
			parent:emit('raw', str)
			if self.handlePayload then -- virtual method
				self:handlePayload(payload)
			end
		end
		self:info('Disconnected')
	else
		self:error('Could not connect to %s (%s)', url, res) -- TODO: get new url?
	end

	self._read = nil
	self._write = nil
	self._identified = nil

	if self.stopHeartbeat then -- virtual method
		self:stopHeartbeat()
	end

	if self.handleDisconnect then -- virtual method
		return self:handleDisconnect(url, path)
	end

end

function WebSocket:parseMessage(message)

	local opcode = message.opcode
	local payload = message.payload

	if opcode == TEXT then

		return decode(payload, 1, null), payload

	elseif opcode == BINARY then

		payload = inflate(payload, 1)
		return decode(payload, 1, null), payload

	elseif opcode == CLOSE then

		local code, i = ('>H'):unpack(payload)
		local msg = #payload > i and payload:sub(i) or 'Connection closed'
		self:warning('%i - %s', code, msg)
		return nil

	end

end

function WebSocket:_send(op, d, identify)
	self._mutex:lock()
	local success, err
	if identify or self._session_id then
		if self._write then
			success, err = self._write {opcode = TEXT, payload = encode {op = op, d = d}}
		else
			success, err = false, 'Not connected to gateway'
		end
	else
		success, err = false, 'Invalid session'
	end
	self._mutex:unlockAfter(GATEWAY_DELAY)
	return success, err
end

function WebSocket:disconnect(reconnect)
	if not self._write then return end
	self._reconnect = not not reconnect
	self._write()
	self._read = nil
	self._write = nil
end

return WebSocket
