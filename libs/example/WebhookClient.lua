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
	
	print("username from the user object: " .. webhookInstance.user.username .. " from Webhook Instance.")

	print("name: " .. webhookInstance.name .. " from Webhook Instance.")
	--print("name: " .. WebhookClient.name .. " from WebhookClient Instance.\n")

	p("Setters")
	print("Changing WebhookClient name")
	webhookInstance:setName("Yes")

	print("Changing WebhookClient avatar")
	--webhookInstance:setAvatar("shah.png")
	
	print("Changing WebhookClient ChannelId")
	webhookInstance:setChannelId("352134636702400512")
	

	p("Functions")
	WebhookClient:send("Hi")

	--[[
	WebhookClient:send("Sending a file.", {
		file = "HelloDiscord.ia",
		wait = true
	})
	]]
	

	-- There's also delete, deleteWithToken, Slack compatible (executeSlackCompatible(body)) - Github compatible (executeGitHubCompatible(body)) webhook functions

	--WebhookClient:setChannelId("352134636702400512"):send("test")

	--[[
	-- ALL THE SETTERS AND MODIFIERS RETURN A WebhookClient INSTANCE

		Set a new username
	WebhookClient:setName("AsyncTest")

		Set a new Avatar (accepts url, path to file or base64 encoded data)
	WebhookClient:setAvatar("shah.png")

		Changes the webhook to the given channelId (only works with a Webhook Instance)
	webhookInstance:setChannelId("id")

		Modify webhook's data (data must be a table)
	WebhookClient:modify({
		username = "changed again",
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
