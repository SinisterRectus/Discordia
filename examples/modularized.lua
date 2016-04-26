local client = require('discordia').Client:new();
local handle = require('./etc/commands.lua');
local config = require('.etc/config.json');
local uptime = os.time;

client:on('ready', function()
	p(string.format('Logged in as %s', client.user.username))
end)

local function getPrefix(message)
	local prefix = string.sub(message, 1)
	
	if (prefix == ".") then
		return true
	end
end

client:on('messageCreate', function(message)
	local prefix = getPrefix(message)
	local sender = message.author
	local client = client.user
	
	if sender ~= client and prefix then
		handle(client, message)
	end
end)

client:run(config.auth.token) --::runBot()
