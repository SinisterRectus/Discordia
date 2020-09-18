local uv = require('uv')
local json = require('json')
local class = require('../class')
local enums = require('../enums')
local helpers = require('../helpers')
local typing = require('../typing')
local package = require('../../package')

local Logger = require('../utils/Logger')
local Emitter = require('../utils/Emitter')
local ContainerClient = require('../mixins/ContainerClient')
local API = require('./API')
local CDN = require('./CDN')
local Shard = require('./Shard')

local wrap = coroutine.wrap
local concat = table.concat
local format = string.format
local attachQuery, readOnly = helpers.attachQuery, helpers.readOnly
local checkEnum = typing.checkEnum

local GATEWAY_VERSION = 6
local GATEWAY_ENCODING = 'json'

local Client, get = class('Client', Emitter)
class.mixin(Client, ContainerClient.methods)

local function checkOption(options, k, expected, default)
	if options == nil then
		return default
	end
	local v = options[k]
	if v == nil then
		return default
	end
	local received = type(v)
	if expected ~= received then
		return error(format('invalid client option %q (expected %s, received %s)', k, expected, received), 3)
	end
	if received == 'number' and (v < 0 or v % 1 > 0) then
		return error(format('invalid client option %q (number must be a positive integer)', k), 3)
	end
	return v
end

local function checkActivity(activity)
	local t = type(activity)
	if t == 'string' then
		return {name = activity, type = 0}
	elseif t == 'table' then
		return {
			name = type(activity.name) == 'string' and activity.name or '',
			type = type(activity.type) == 'number' and activity.type or 0,
			url = type(activity.url) == 'string' and activity.url or nil,
		}
	end
	return error('invalid activity', 2)
end

function Client:__init(opt)
	Emitter.__init(self)
	self._routeDelay = checkOption(opt, 'routeDelay', 'number', 250)
	self._maxRetries = checkOption(opt, 'maxRetries', 'number', 5)
	self._tokenPrefix = checkOption(opt, 'tokenPrefix', 'string', 'Bot ')
	self._gatewayIntents = checkOption(opt, 'gatewayIntents', 'number', nil)
	self._totalShardCount = checkOption(opt, 'totalShardCount', 'number', nil)
	self._payloadCompression = checkOption(opt, 'payloadCompression', 'boolean', true)
	self._defaultImageExtension = checkOption(opt, 'defaultImageExtension', 'string', 'png')
	self._defaultImageSize = checkOption(opt, 'defaultImageSize', 'number', 1024)
	self._logger = Logger(
		checkOption(opt, 'logLevel', 'number', enums.logLevel.info),
		checkOption(opt, 'dateFormat', 'string', '%F %T'),
		checkOption(opt, 'logFile', 'string', 'discordia.log'),
		checkOption(opt, 'logColors', 'boolean', true)
	)
	self._api = API(self)
	self._cdn = CDN(self)
	self._shards = {}
	self._token = nil
	self._userId = nil
	self._status = opt.status and checkEnum(enums.status, opt.status)
	self._activity = opt.activity and checkActivity(opt.activity)
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

	local user, err1 = self.api:getCurrentUser()
	if not user then
		return self:log('critical', 'Could not get user information: %s', err1)
	end
	self._userId = user.id
	self:log('info', 'Authenticated as %s#%s', user.username, user.discriminator)

	local shards = self._totalShardCount
	if shards == 0 then
		self:log('info', 'Readying client with no gateway connection(s)')
		return self:emit('ready')
	end

	local gateway, err2 = self.api:getGatewayBot()
	if not gateway then
		return self:log('critical', 'Could not get gateway information: %s', err2)
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
	self.api:setToken(token)
end

function Client:setStatus(status)
	self._status = status and checkEnum(enums.status, status)
	for _, shard in pairs(self._shards) do
		shard:updatePresence(self._status, self._activity)
	end
end

function Client:setActivity(activity)
	self._activity = activity and checkActivity(activity)
	for _, shard in pairs(self._shards) do
		shard:updatePresence(self._status, self._activity)
	end
end

function Client:setUsername(username)
	return self:modifyCurrentUser({username = username or json.null})
end

function Client:setAvatar(avatar)
	return self:modifyCurrentUser({avatar = avatar or json.null})
end

----

function get:routeDelay()
	return self._routeDelay
end

function get:maxRetries()
	return self._maxRetries
end

function get:tokenPrefix()
	return self._tokenPrefix
end

function get:gatewayIntents()
	return self._gatewayIntents
end

function get:totalShardCount()
	return self._totalShardCount
end

function get:payloadCompression()
	return self._payloadCompression
end

function get:defaultImageExtension()
	return self._defaultImageExtension
end

function get:defaultImageSize()
	return self._defaultImageSize
end

function get:status()
	return self._status
end

function get:activity()
	return readOnly(self._activity)
end

function get:logger()
	return self._logger
end

function get:token()
	return self._token
end

function get:api()
	return self._api
end

function get:cdn()
	return self._cdn
end

function get:userId()
	return self._userId
end

return Client
