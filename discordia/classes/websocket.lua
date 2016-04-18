local los = require('los')
local json = require('json')
local websocket = require('coro-websocket')

class('WebSocket')

function WebSocket:__init(gateway)
	if gateway then self:connect(gateway) end
end

function WebSocket:connect(gateway)
	gateway = gateway .. '/' -- hotfix for codec error
	local options = websocket.parseUrl(gateway)
	self.res, self.read, self.write = websocket.connect(options)
end

function WebSocket:send(payload)
	local message = {opcode = 1, payload = json.encode(payload)}
	return self.write(message)
end

function WebSocket:receive()
	local message = self.read()
	if not message then return end -- need to handle this
	return json.decode(message.payload)
end

function WebSocket:op1(sequence)
	self:send({
		op = 1,
		d = sequence -- formerly os.time()
	})
end

function WebSocket:op2(token)
	self:send({
		op = 2,
		d = {
			token = token,
			v = 3,
			properties = {
				['$os'] = los.type(),
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

function WebSocket:op8(guildId)
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
