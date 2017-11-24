local discordia = require('discordia')
local client = discordia.Client()
local WebhookClient

client:on("ready", function()
	WebhookClient = discordia.WebhookClient("id", "token", {name = "Discordia's new era!"})
	local webhookInstance = client:getWebhook("id")
	
	p("Getters")
	print("token: " .. webhookInstance.token .. " from Webhook Instance.")
	print("token: " .. WebhookClient.token .. " from WebhookClient Instance.\n")

	print("ID: " .. webhookInstance.id .. " from Webhook Instance.")
	print("ID: " .. WebhookClient.id .. " from WebhookClient Instance.\n")

	print("avatarURL: " .. webhookInstance.avatarURL .. " from Webhook Instance.")
	print("avatarURL: " .. WebhookClient.avatarURL .. " from WebhookClient Instance.\n")

	print("guildId: " .. webhookInstance.guildId .. " from Webhook Instance.")
	print("guildId: " .. WebhookClient.guildId .. " from WebhookClient Instance.\n")

	print("channelId: " .. webhookInstance.channelId .. " from Webhook Instance.")
	print("channelId: " .. WebhookClient.channelId .. " from WebhookClient Instance.\n")
	
	print("user id from the user object: " .. webhookInstance.user.id .. " from Webhook Instance.")
	print("user id from the user object: " .. WebhookClient.user.id .. " from WebhookClient Instance.\n")
	
	print("username from the user object: " .. webhookInstance.user.username .. " from Webhook Instance.")
	print("username from the user object: " .. WebhookClient.user.username .. " from WebhookClient Instance.\n")

	print("name: " .. webhookInstance.name .. " from Webhook Instance.")
	print("name: " .. WebhookClient.name .. " from WebhookClient Instance.\n")

	p("Setters")
	print("setAvatar (changed to " .. webhookInstance:setAvatar("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTLqkouhfu-48ykx-9ldL71nCbb6eEj9sp2y3fUW5Mg9hQtJV86").avatarURL .. " url) from Webhook Instance.")
	print("setAvatar (changed to " .. WebhookClient:setAvatar("https://media.discordapp.net/attachments/381890411414683648/382873214352883713/unknown.png?width=921&height=167").avatarURL .. " url) from WebhookClient Instance.\n")

	print("setChannelId (changed to " .. webhookInstance:setChannelId("379618743497654275").channelId .. " channelId) from Webhook Instance.")
	print("setChannelId (changed to " .. WebhookClient:setChannelId("379618743497654275").channelId .. " channelId) from WebhookClient Instance.\n")

	print("setName (changed to " .. webhookInstance:setName("AsyncRocks").name .. " name) from Webhook Instance.")
	print("setName (changed to " .. WebhookClient:setName("AsyncRocks").name .. " name) from WebhookClient Instance.\n")

	p("Functions")
	print("sent 'blah' and received a Message object. ID is: " .. webhookInstance:send("blah").id .. " from Webhook Instance.") -- send returns two objects: Message and self
	print("sent 'bleh' and received a Message object. ID is: " .. WebhookClient:send("bleh").id .. " from WebhookClient Instance.\n")

	WebhookClient:send("Sending a file.", {
		file = "HelloDiscord.ia"
	})
	-- There's also delete, deleteWithToken, Slack compatible (executeSlackCompatible(body)) - Github compatible (executeGitHubCompatible(body)) webhook functions

	--WebhookClient:setChannelId("352134636702400512"):send("test")

	--[[
	-- ALL THE SETTERS AND MODIFIERS RETURN A WebhookClient INSTANCE

		Set a new username
	WebhookClient:setName("AsyncTest")

		Set a new Avatar (accepts url, path to file or base64 encoded data)
	WebhookClient:setAvatar("https://avatars2.githubusercontent.com/u/8753175?v=4&s=400")

		Changes the webhook to the given channelId (accepts url, path to file or base64 encoded data)
	WebhookClient:setChannelId("id")

		Modify webhook's data (data must be a table)
	WebhookClient:modify({
		username = "changed again",
		channelId = "352134636702400512",
		avatarURL = "https://avatars2.githubusercontent.com/u/8753175?v=4&s=400"
	})

		Delete the webhook
	WebhookClient:delete()

	

		Embedded message
	WebhookClient:send("Sending embedded message.", {
		embeds = {
			{
				title = "Test",
				description = "Is this working?",
				color = 15020811
			}
		}
	})
	
		Sending a file
	WebhookClient:send("Sending a file.", {
		file = "HelloDiscord.ia"
	})


	]]
end)

client:on("messageCreate", function(message)
	local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content

	if cmd == "!avatar" then
		if arg then
			WebhookClient:setAvatar(arg):send("Avatar changed.")
		end
	end
end)

client:run("Bot token")
