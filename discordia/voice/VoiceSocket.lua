local uv = require('uv')
local json = require('json')
local timer = require('timer')
local websocket = require('coro-websocket')
local Buffer = require('../utils/Buffer')
local ffi = require('ffi')
local constants = require('./constants')

local time = os.time
local encode, decode = json.encode, json.decode
local wrap, yield = coroutine.wrap, coroutine.yield
local connect = websocket.connect
local setInterval, clearInterval = timer.setInterval, timer.clearInterval

local MODE = constants.MODE

local VoiceSocket = class('VoiceSocket')

function VoiceSocket:__init(voice)
	self._voice = voice
end

function VoiceSocket:connect(endpoint)
	self._res, self._read, self._write = connect({
		host = endpoint:gsub(':.*', ''),
		port = 443,
		tls = true,
	})
	self._connected = self._res and self._res.code == 101
	return self._connected
end

function VoiceSocket:disconnect()
	if not self._connected then return end
	self._connected = false
	self:stopHeartbeat()
	self._write()
	self._res, self._read, self._write = nil, nil, nil
end

function VoiceSocket:handlePayloads(id, connection)

	local voice = self._voice
	local udp = uv.new_udp()

	for data in self._read do

		local payload = decode(data.payload)
		local op, d = payload.op, payload.d

		if op == 2 then
			self:startHeartbeat(d.heartbeat_interval)
			self:handshake(connection, udp, d.ip, d.port, d.ssrc)
		elseif op == 4 then
			connection._key = ffi.new('const unsigned char[32]', d.secret_key)
			voice:_resumeJoin(id)
		end

	end

	connection._closed = true
	udp:close()
	voice:_resumeLeave(id)

end

function VoiceSocket:handshake(connection, udp, ip, port, ssrc)

	connection:_prepare(udp, ip, port, ssrc)

	udp:recv_start(function(err, msg)
		assert(not err, err)
		if msg then
			udp:recv_stop()
			local address = msg:match('%d.*%d')
			local a, b = msg:sub(-2):byte(1, 2)
			self:selectProtocol({
				address = address,
				port = a + b * 0x100,
				mode = MODE,
			})
		end
	end)

	local buffer = Buffer(70)
	buffer:writeUInt32LE(0, ssrc)
	udp:send(tostring(buffer), ip, port)

end

function VoiceSocket:startHeartbeat(interval)
	if self._heartbeatInterval then clearInterval(self._heartbeatInterval) end
	self._heartbeatInterval = setInterval(interval, wrap(function()
		while true do yield(self:heartbeat()) end
	end))
end

function VoiceSocket:stopHeartbeat()
	if not self._heartbeatInterval then return end
	clearInterval(self._heartbeatInterval)
	self._heartbeatInterval = nil
end

local function send(self, op, d)
	return wrap(self._write)({
		opcode = 1,
		payload = encode({op = op, d = d})
	})
end

function VoiceSocket:identify(data)
	return send(self, 0, data)
end

function VoiceSocket:selectProtocol(data)
	return send(self, 1, {
		protocol = 'udp',
		data = data
	})
end

function VoiceSocket:heartbeat()
	return send(self, 3, time())
end

function VoiceSocket:setSpeaking(speaking)
	return send(self, 5, {
		speaking = speaking,
		delay = 0,
	})
end

return VoiceSocket
