local VoiceSocket = require('./VoiceSocket')
local VoiceConnection = require('./VoiceConnection')
local constants = require('./constants')

local CHANNELS = constants.CHANNELS
local SAMPLE_RATE = constants.SAMPLE_RATE

local format = string.format
local wrap, resume = coroutine.wrap, coroutine.resume

local VoiceManager, property, method = class('VoiceManager')
VoiceManager.__description = "The client's handler of voice connections."

function VoiceManager:__init(client)
	self._client = client
	self._connections = {}
	self._joining = {}
	self._leaving = {}
end

local opus
local function loadOpus(self, filename)
	opus = opus or require('./opus')(filename or 'opus')
	self._opus = opus
end

local sodium
local function loadSodium(self, filename)
	sodium = sodium or require('./sodium')(filename or 'sodium')
	self._sodium = sodium
end

function VoiceManager:_createVoiceConnection(data, channel, state)

	local socket = VoiceSocket(self)
	local encoder = opus.Encoder(SAMPLE_RATE, CHANNELS)

	local connection = VoiceConnection(encoder, channel, socket, self)
	self._connections[state.guild_id] = connection
	connection:setBitrate(self._client._options.bitrate)

	wrap(function()
		local connected, err = socket:connect(data.endpoint)
		if connected then
			socket:identify({
				server_id = state.guild_id,
				user_id = state.user_id,
				session_id = state.session_id,
				token = data.token,
			})
			return socket:handlePayloads(state.guild_id, connection)
		else
			self._client:warning(format('Could not connect to voice gateway (%s)', err))
		end
	end)()

end

function VoiceManager:_resumeJoin(id, timeout)
	local connection = self._connections[id]
	if connection then
		connection._channel._parent._connection = connection
	end
	local thread = self._joining[id]
	self._joining[id] = nil
	if thread then
		if timeout then
			return assert(resume(thread, nil))
		else
			return assert(resume(thread, connection))
		end
	end
end

function VoiceManager:_resumeLeave(id, timeout)
	local connection = self._connections[id]
	if connection then
		connection._channel._parent._connection = nil
		self._connections[id] = nil
	end
	local thread = self._leaving[id]
	self._leaving[id] = nil
	if thread then
		if timeout then
			return assert(resume(thread, false))
		else
			return assert(resume(thread, true))
		end
	end
end

local function getConnections(self)
	local k, v
	local connections = self._connections
	return function()
		k, v = next(connections, k)
		return v
	end
end

local function pauseStreams(self)
	for _, connection in pairs(self._connections) do
		if connection._stream then
			connection._stream:pause()
		end
	end
end

local function resumeStreams(self)
	for _, connection in pairs(self._connections) do
		if connection._stream then
			connection._stream:resume()
		end
	end
end

local function stopStreams(self)
	for _, connection in pairs(self._connections) do
		if connection._stream then
			connection._stream:stop()
		end
	end
end

property('connections', getConnections, nil, 'function', "An iterator for the client's active voice connections")

method('loadOpus', loadOpus, 'path', "Loads a dynamic libopus file (.dll, .so).")
method('loadSodium', loadSodium, 'path', "Loads a dynamic libsodium file (.dll, .so).")
method('pauseStreams', pauseStreams, nil, "Pauses active audio streams for all existing connections.", 'WS')
method('resumeStreams', resumeStreams, nil, "Resumes active audio streams for all existing connections.", 'WS')
method('stopStreams', stopStreams, nil, "Stops active audio streams for all existing connections.", 'WS')

return VoiceManager
