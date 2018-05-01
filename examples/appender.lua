local discordia = require("discordia")
local client = discordia.Client()

local lines = {} -- blank table of messages

client:on("ready", function() -- bot is ready
	print("Logged in as " .. client.user.username)
end)

client:on("messageCreate", function(message)

	local content = message.content
	local author = message.author

	if author == client.user then return end -- the bot should not append its own messages

	if content == "!lines" then -- if the lines command is activated
		message.channel:send {
			file = {"lines.txt", table.concat(lines, "\n")} -- concatenate and send the collected lines in a file
		}
		lines = {} -- empty the lines table
	else -- if the lines command is NOT activated
		table.insert(lines, content) -- append the message as a new line
	end

end)

client:run("Bot BOT_TOKEN") -- replace BOT_TOKEN with your bot token
