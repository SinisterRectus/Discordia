local jit = require('jit')
local json = require('json')
local timer = require('timer')
local websocket = require('coro-websocket')
local EventHandler = require('./EventHandler')

local ignore = {
	['MESSAGE_ACK'] = true,
	['CHANNEL_PINS_UPDATE'] = true,
}

local Socket = class('Socket')

function Socket:__init(client)
	self.client = client
end

function Socket:connect(gateway)
	local options = websocket.parseUrl(gateway .. '/')
	options.pathname = options.pathname .. '?v=5'
	self.res, self.read, self.write = websocket.connect(options)
	return self.res and self.res.code == 101
end

function Socket:reconnect()
	self:stopHeartbeat()
	self.res, self.read, self.write = nil, nil, nil
	warning('WebSocket disconnected, attempting to reconnect...')
	timer.sleep(5000)
	self.client:connectWebSocket()
end

function Socket:disconnect()
	return self.write()
end

function Socket:handlePayloads()
	local read = self.read
	local client = self.client
	for data in read do
		self:handlePayload(data, client)
	end
	self:reconnect()
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
				handler(payload.d, client)
			else
				warning('Unhandled event: ' .. payload.t)
			end
		end
	elseif op == 1 then
		self:heartbeat()
	elseif op == 7 then
		self:reconnect()
	elseif op == 9 then
		warning('Invalid session, attempting to re-identify...')
		self:identify()
	elseif op == 10 then
		self:startHeartbeat(payload.d.heartbeat_interval)
		if client.sessionId then
			self:resume()
		else
			self:identify()
		end
	elseif op == 11 then
		-- heartbeat acknowledged
	else
		warning('Unhandled payload: ' .. op)
	end

end

function Socket:startHeartbeat(interval)
	self.heartbeatInterval = timer.setInterval(interval, coroutine.wrap(function()
		while true do coroutine.yield(self:heartbeat()) end
	end))
end

function Socket:stopHeartbeat(interval)
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
	self:send({
		op = 1,
		d = self.sequence
	})
end

function Socket:identify()
	self:send({
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
	self:send({
		op = 3,
		d = {
			idle_since = idleSince or json.null,
			game = {name = gameName or json.null},
		}
	})
end

function Socket:resume()
	self:send({
		op = 6,
		d = {
			token = self.client.token,
			session_id = self.client.sessionId,
			seq = self.sequence
		}
	})
end

function Socket:requestGuildMembers(guildId)
	self:send({
		op = 8,
		d = {
			guild_id = guildId,
			query = '',
			limit = 0
		}
	})
end

function Socket:syncGuilds(guildIds)
	self:send({
		op = 12,
		d = guildIds
	})
end

return Socket
