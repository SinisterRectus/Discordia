local jit = require('jit')
local json = require('json')
local timer = require('timer')
local websocket = require('coro-websocket')
local EventHandler = require('./EventHandler')

local decode = json.decode
local format = string.format
local min, max = math.min, math.max
local wrap, yield = coroutine.wrap, coroutine.yield
local parseUrl, connect = websocket.parseUrl, websocket.connect
local info, warning, failure = console.info, console.warning, console.failure
local sleep, setInterval, clearInterval = timer.sleep, timer.setInterval, timer.clearInterval

local Socket = class('Socket')

function Socket:__init(client)
	self.client = client
	self.backoff = 1024
end

function Socket:incrementReconnectTime()
	self.backoff = min(self.backoff * 2, 65536)
end

function Socket:decrementReconnectTime()
	self.backoff = max(self.backoff / 2, 1024)
end

function Socket:connect(gateway)
	local options = parseUrl(gateway .. '/')
	options.pathname = options.pathname .. '?v=5'
	self.res, self.read, self.write = connect(options)
	self.connected = self.res and self.res.code == 101
	return self.connected
end

function Socket:reconnect()
	if self.connected then self:disconnect() end
	return self.client:connectWebSocket()
end

function Socket:disconnect()
	if not self.connected then return end
	self.connected = false
	self:stopHeartbeat()
	self.write()
	self.res, self.read, self.write = nil, nil, nil
end

function Socket:handleUnexpectedDisconnect()
	warning(format('Attemping to reconnect after %i ms...', self.backoff))
	sleep(self.backoff)
	self:incrementReconnectTime()
	if not pcall(self.reconnect, self) then
		return self:handleUnexpectedDisconnect()
	end
end

function Socket:handlePayloads()
	local read = self.read
	local client = self.client
	for data in read do
		self:handlePayload(data, client)
	end
	if self.connected then
		self.connected = false
		self:stopHeartbeat()
		warning('WebSocket disconnected unexpectedly')
		return self:handleUnexpectedDisconnect()
	end
end

function Socket:handlePayload(data, client)

	local string = data.payload
	local payload = decode(string)

	client:emit('raw', payload, string)

	local op = payload.op

	if op == 0 then
		self.sequence = payload.s
		local handler = EventHandler[payload.t]
		if handler then
			return handler(payload.d, client)
		else
			return warning('Unhandled event: ' .. payload.t)
		end
	elseif op == 1 then
		return self:heartbeat()
	elseif op == 7 then
		return self:reconnect()
	elseif op == 9 then
		warning('Invalid session, attempting to re-identify...')
		return self:identify()
	elseif op == 10 then
		self:startHeartbeat(payload.d.heartbeat_interval)
		if client.sessionId then
			return self:resume()
		else
			return self:identify()
		end
	elseif op == 11 then
		return -- heartbeat acknowledged
	else
		return warning('Unhandled payload: ' .. op)
	end

end

function Socket:startHeartbeat(interval)
	self.heartbeatInterval = setInterval(interval, wrap(function()
		while true do
			self:decrementReconnectTime()
			yield(self:heartbeat())
		end
	end))
end

function Socket:stopHeartbeat()
	if not self.heartbeatInterval then return end
	clearInterval(self.heartbeatInterval)
	self.heartbeatInterval = nil
end

function Socket:send(payload)
	return self.write({
		opcode = 1,
		payload = json.encode(payload)
	})
end

function Socket:heartbeat()
	return self:send({
		op = 1,
		d = self.sequence
	})
end

function Socket:identify()
	return self:send({
		op = 2,
		d = {
			token = self.client.token,
			properties = {
				['$os'] = jit.os,
				['$browser'] = 'Discordia',
				['$device'] = 'Discordia',
				['$referrer'] = '',
				['$referring_domain'] = ''
			},
			large_threshold = self.client.options.largeThreshold,
			compress = false,
		}
	})
end

function Socket:statusUpdate(idleSince, gameName)
	return self:send({
		op = 3,
		d = {
			idle_since = idleSince or json.null,
			game = {name = gameName or json.null},
		}
	})
end

function Socket:resume()
	return self:send({
		op = 6,
		d = {
			token = self.client.token,
			session_id = self.client.sessionId,
			seq = self.sequence
		}
	})
end

function Socket:requestGuildMembers(guildId)
	return self:send({
		op = 8,
		d = {
			guild_id = guildId,
			query = '',
			limit = 0
		}
	})
end

function Socket:syncGuilds(guildIds)
	return self:send({
		op = 12,
		d = guildIds
	})
end

return Socket
