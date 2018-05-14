local discordia = require('discordia')
local client = discordia.Client()
discordia.extensions() -- load all helpful extensions

local prefix = "."
local commands = {
	[prefix .. "ping"] = {
		description = "Answers with pong.",
		exec = function(message)
			message.channel:send("Pong!")
		end
	},
	[prefix .. "hello"] = {
		description = "Answers with world.",
		exec = function(message)
			message.channel:send("world!")
		end
	}
}

client:on('ready', function()
	p(string.format('Logged in as %s', client.user.username))
end)

client:on("messageCreate", function(message)
	local args = message.content:split(" ") -- split all arguments into a table

	local command = commands[prefix..args[1]]
	if command then -- ping or hello
		command.exec(message) -- execute the command
	end

	if args[1] == prefix.."help" then -- display all the commands
		local output = {}
		for word, tbl in pairs(commands) do
			table.insert(output, "Command: " .. word .. "\nDescription: " .. tbl.description)
		end

		message:reply(table.concat(output, "\n\n"))
	end
end)


client:run("Bot BOT_TOKEN") -- replace BOT_TOKEN with your bot token
