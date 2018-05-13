local TOKEN = "Bot's token"
local discordia = require('discordia')
local client = discordia.Client()

local commands = {
	ping = {
		description = "Answers with pong.",
		exec = function(message)
			message.channel:send("Pong!")
		end
	},
	hello = {
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
	local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content

	local command = commands[cmd]
	if command then -- ping or hello
		command.exec(message) -- execute the command
	end

	if cmd == "help" then -- display all the commands
		local output = ""
		for word, tbl in pairs(commands) do
			output = output .. "Command: " .. word .. "\nDescription: " .. tbl.description .. "\n\n"
		end

		message:reply(output)
	end
end)


client:run("Bot " .. TOKEN)
