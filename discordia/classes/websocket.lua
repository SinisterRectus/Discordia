local jit = require('jit')
local json = require('json')
local websocket = require('coro-websocket')

local WebSocket = class('WebSocket')

function WebSocket:__init(gateway)
	self.gateway = gateway .. '/'
end

function WebSocket:connect()
	local options = websocket.parseUrl(self.gateway)
	self.res, self.read, self.write = websocket.connect(options)
end

function WebSocket:disconnect()
	self.write()
end

function WebSocket:send(payload)
	local message = {opcode = 1, payload = json.encode(payload)}
	return self.write(message)
end

function WebSocket:receive()
	local message = self.read()
	if not message then return end
	return json.decode(message.payload)
end

function WebSocket:heartbeat(sequence)
	self:send({
		op = 1,
		d = sequence
	})
end

function WebSocket:identify(token)
	self:send({
		op = 2,
		d = {
			token = token,
			properties = {
				['$os'] = jit.os,
				['$browser'] = 'Discordia',
				['$device'] = 'Discordia',
				['$referrer'] = '',
				['$referring_domain'] = ''
			},
			large_threshold = 100, -- 50 to 250
			compress = false
		}
	})
end

function WebSocket:statusUpdate(idleSince, gameName)
	self:send({
		op = 3,
		d = {
			idle_since = idleSince or json.null,
			game = {name = gameName or json.null}
		}
	})
end

function WebSocket:resume(token, sessionId, sequence)
	self:send({
		op = 6,
		d = {
			token = token,
			session_id = sessionId,
			seq = sequence
		}
	})
end

function WebSocket:requestGuildMembers(guildId)
	self:send({
		op = 8,
		d = {
			guild_id = guildId,
			query = '',
			limit = 0
		}
	})
end

return WebSocket
