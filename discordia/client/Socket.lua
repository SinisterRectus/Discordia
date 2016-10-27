local jit = require('jit')
local json = require('json')
local timer = require('timer')
local websocket = require('coro-websocket')
local EventHandler = require('./EventHandler')

local ignore = {
	['MESSAGE_ACK'] = true,
	['CHANNEL_PINS_UPDATE'] = true,
	['MESSAGE_REACTION_ADD'] = true,
	['MESSAGE_REACTION_REMOVE'] = true,
}

local Socket = class('Socket')

function Socket:__init(client)
	self.client = client
	self.backoff = 1024
end

function Socket:incrementReconnectTime()
	self.backoff = math.min(self.backoff * 2, 65536)
end

function Socket:decrementReconnectTime()
	self.backoff = math.max(self.backoff / 2, 1024)
end

function Socket:connect(gateway)
	local options = websocket.parseUrl(gateway .. '/')
	options.pathname = options.pathname .. '?v=5'
	self.res, self.read, self.write = websocket.connect(options)
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
	warning(string.format('Attemping to reconnect after %i ms...', self.backoff))
	timer.sleep(self.backoff)
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
	local payload = json.decode(string)

	client:emit('raw', payload, string)

	local op = payload.op

	if op == 0 then
		self.sequence = payload.s
		if not ignore[payload.t] then
			local handler = EventHandler[payload.t]
			if handler then
				return handler(payload.d, client)
			else
				return warning('Unhandled event: ' .. payload.t)
			end
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
	self.heartbeatInterval = timer.setInterval(interval, coroutine.wrap(function()
		while true do
			self:decrementReconnectTime()
			coroutine.yield(self:heartbeat())
		end
	end))
end

function Socket:stopHeartbeat()
	if not self.heartbeatInterval then return end
	timer.clearInterval(self.heartbeatInterval)
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
