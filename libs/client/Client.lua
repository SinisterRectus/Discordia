local uv = require('uv')
local json = require('json')
local class = require('../class')
local enums = require('../enums')
local helpers = require('../helpers')
local typing = require('../typing')
local package = require('../../package')

local Logger = require('../utils/Logger')
local Emitter = require('../utils/Emitter')
local API = require('./API')
local Shard = require('./Shard')

local null = json.null
local wrap = coroutine.wrap
local concat = table.concat
local format = string.format
local attachQuery, newProxy = helpers.attachQuery, helpers.newProxy
local checkEnum = typing.checkEnum

local GATEWAY_VERSION = 6
local GATEWAY_ENCODING = 'json'

local Client, get = class('Client', Emitter)

local defaultOptions = { -- {type, value}
	routeDelay = {'number', 250},
	maxRetries = {'number', 5},
	tokenPrefix = {'string', 'Bot '},
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

local function checkOption(k, v, level)
	if not defaultOptions[k] then
		return error('invalid client option: ' .. k, level)
	end
	local expected = defaultOptions[k][1]
	local received = type(v)
	if expected ~= received then
		return error(format('invalid option %q (expected %s, received %s)', k, expected, received), level)
	end
	if received == 'number' and (v < 0 or v % 1 > 0) then
		return error(format('invalid option %q (number must be a positive integer)', k), level)
	end
	return v
end

local function checkOptions(customOptions)
	local options = {}
	for k, v in pairs(defaultOptions) do
		options[k] = v[2]
	end
	if type(customOptions) == 'table' then
		for k, v in pairs(customOptions) do
			options[k] = checkOption(k, v, 4)
		end
	end
	return options
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
	self._options = opt
	self._logger = Logger(opt.logLevel, opt.dateTime, opt.logFile, opt.logColors)
	self._api = API(self)
	self._shards = {}
	self._token = nil
	self._presence = {
		status = opt.status and checkEnum(enums.status, opt.status) or null,
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
		return self:log('critical', 'Could not get user information: %s', err1)
	end
	self:log('info', 'Authenticated as %s#%s', user.username, user.discriminator)

	local options = self._options
	local shards = options.totalShardCount
	if shards == 0 then
		self:log('info', 'Readying client with no gateway connection(s)')
		return self:emit('ready')
	end

	local gateway, err2 = self._api:getGatewayBot()
	if not gateway then
		return self:log('critical', 'Could not get gateway information: %s', err2)
	end

	if shards == nil then
		shards = gateway.shards
	elseif shards ~= gateway.shards then
		self:log('warning', 'Indicated shard count (%i) is different from recommended (%i)', shards, gateway.shards)
	end
	options.totalShardCount = shards

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
	self._presence.status = status and checkEnum(enums.status, status) or null
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

function get:options()
	local options = self._options
	return newProxy(options, function(_, k, v)
		options[k] = checkOption(k, v, 2)
	end)
end

function get:presence()
	return newProxy(self._presence, function()
		return error('cannot overwrite presence table')
	end)
end

return Client
