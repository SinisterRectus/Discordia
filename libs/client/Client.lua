local uv = require('uv')
local json = require('json')
local class = require('../class')
local enums = require('../enums')
local helpers = require('../helpers')
local package = require('../../package')

local Logger = require('../utils/Logger')
local Emitter = require('../utils/Emitter')
local API = require('./API')
local Shard = require('./Shard')

local null = json.null
local wrap = coroutine.wrap
local concat = table.concat
local format = string.format
local attachQuery = helpers.attachQuery

local GATEWAY_VERSION = 6
local GATEWAY_ENCODING = 'json'

local Client, get = class('Client', Emitter)

local defaultOptions = { -- {type, value}
	routeDelay = {'number', 250},
	maxRetries = {'number', 5},
	gatewayIntents = {'number', nil},
	totalShardCount = {'number', nil},
	payloadCompression = {'boolean', true},
	logLevel = {'number', enums.logLevel.info},
	dateTime = {'string', '%F %T'},
	logFile = {'string', 'discordia.log'},
	logColors = {'boolean', true},
	status = {'string', nil},
	activity = {'table', nil},
}

local function checkOptions(customOptions)
	if type(customOptions) == 'table' then
		local options = {}
		for k, default in pairs(defaultOptions) do -- load options
			local custom = customOptions[k]
			if custom == nil then
				options[k] = default[2]
			else
				options[k] = custom
			end
		end
		for k, v in pairs(customOptions) do -- validate options
			local expected = defaultOptions[k][1]
			local received = type(v)
			if expected ~= received then
				error(format('invalid option %q (expected %s, received %s)', k, expected, received), 4)
			end
			if received == 'number' and (v < 0 or v % 1 > 0) then
				error(format('invalid option %q (number must be a positive integer)', k), 4)
			end
		end
		return options
	else
		return defaultOptions
	end
end

local function optStatus(status)
	return type(status) == 'string' and #status > 0 and status or null
end

local function optActivity(activity)
	return type(activity) == 'table' and type(activity.name) == 'string' and #activity.name > 0 and {
		name = activity.name,
		type = type(activity.type) == 'number' and activity.type or 0,
		url = type(activity.url) == 'string' and activity.url or nil,
	} or null
end

function Client:__init(opt)
	Emitter.__init(self)
	opt = checkOptions(opt)
	self._routeDelay = opt.routeDelay
	self._maxRetries = opt.maxRetries
	self._gatewayIntents = opt.gatewayIntents
	self._totalShardCount = opt.totalShardCount
	self._payloadCompression = opt.payloadCompression
	self._logger = Logger(opt.logLevel, opt.dateTime, opt.logFile, opt.logColors)
	self._api = API(self)
	self._shards = {}
	self._token = nil
	self._presence = {
		status = optStatus(opt.status),
		game = optActivity(opt.activity),
		since = null,
		afk = null,
	}
end

function Client:_run(token)

	self:log('info', 'Discordia %s', package.version)
	self:log('info', 'Connecting to Discord...')

	local signal = uv.new_signal()
	signal:start(uv.constants.SIGINT, function()
		signal:stop()
		signal:close()
		return wrap(self.stop)(self)
	end)

	self:setToken(token)

	local user, err1 = self._api:getCurrentUser()
	if not user then
		return self:log('error', 'Could not get user information: %s', err1)
	end
	self:log('info', 'Authenticated as %s#%s', user.username, user.discriminator)

	local shards = self._totalShardCount
	if shards == 0 then
		self:log('info', 'Readying client with no gateway connection(s)')
		return self:emit('ready')
	end

	local gateway, err2 = self._api:getGatewayBot()
	if not gateway then
		return self:log('error', 'Could not get gateway information: %s', err2)
	end

	if shards == nil then
		shards = gateway.shards
	elseif shards ~= gateway.shards then
		self:log('warning', 'Indicated shard count (%i) is different from recommended (%i)', shards, gateway.shards)
	end

	self._totalShardCount = shards

	local l = gateway.session_start_limit
	self:log('info', '%i of %i session starts consumed', l.total - l.remaining, l.total)

	for id = 0, shards - 1 do
		self._shards[id] = Shard(id, self)
	end

	local path = {'/'}
	attachQuery(path, {v = GATEWAY_VERSION, encoding = GATEWAY_ENCODING})
	path = concat(path)

	for id = 0, shards - 1 do
		local shard = self._shards[id]
		wrap(shard.connect)(shard, gateway.url, path)
		shard:identifyWait()
	end

end

function Client:_internalPresence()
	return self._presence
end

----

function Client:log(level, msg, ...)
	return self._logger:log(level, msg, ...)
end

function Client:run(token)
	return wrap(self._run)(self, token)
end

function Client:stop()
	for _, shard in pairs(self._shards) do
		shard:disconnect(false)
	end
end

function Client:setToken(token)
	self._token = token
	self._api:setToken(token)
end

function Client:setStatus(status)
	self._presence.status = optStatus(status)
	for _, shard in pairs(self._shards) do
		shard:updatePresence(self._presence)
	end
end

function Client:setActivity(activity)
	self._presence.game = optActivity(activity)
	for _, shard in pairs(self._shards) do
		shard:updatePresence(self._presence)
	end
end

----

function get:token()
	return self._token
end

function get:routeDelay()
	return self._routeDelay
end

function get:maxRetries()
	return self._maxRetries
end

function get:totalShardCount()
	return self._totalShardCount
end

function get:payloadCompression()
	return self._payloadCompression
end

return Client
