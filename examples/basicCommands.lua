local discordia = require("discordia")
local client = discordia.Client()

discordia.extensions() -- load all helpful extensions

client:on("ready", function() -- bot is ready
	print("Logged in as " .. client.user.username)
end)

client:on("messageCreate", function(message)

	local content = message.content
	local args = content:split(" ") -- split all arguments into a table

	if args[1] == "!ping" then
		message:reply("Pong!")
	elseif args[1] == "!echo" then
		table.remove(args, 1) -- remove the first argument (!echo) from the table
		message:reply(table.concat(args, " ")) -- concatenate the arguments into a string, then reply with it
	end

end)


client:run("Bot BOT_TOKEN") -- replace BOT_TOKEN with your bot token
