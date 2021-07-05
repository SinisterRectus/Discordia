local enums = require('../enums')
local typing = require('../typing')
local messaging = require('../messaging')

local opt = typing.opt
local checkType = typing.checkType
local checkEnum = typing.checkEnum
local checkArray = typing.checkArray
local checkSnowflake = typing.checkSnowflake

local parseFiles = messaging.parseFiles
local parseEmbeds = messaging.parseEmbeds
local parseContent = messaging.parseContent
local parseAllowedMentions = messaging.parseAllowedMentions
local checkBitfield = messaging.checkBitfield

local Client = {}

local function checkChoice(choice)
	checkType('table', choice)
	return {
		name = checkType('string', choice.name),
		value = checkType('string', choice.value),
	}
end

local function checkOption(option)
	checkType('table', option)
	return {
		type = checkEnum(enums.commandOptionType, option.type),
		name = checkType('string', option.name),
		description = checkType('string', option.description),
		required = opt(option.required, checkType, 'boolean'),
		choices = opt(option.choices, checkArray, checkChoice),
		options = opt(option.options, checkArray, checkOption),
	}
end

local function checkCommand(command)
	checkType('table', command)
	return {
		name = checkType('string', command.name),
		description = checkType('string', command.description),
		default_permission = opt(command.defaultPermission, checkType, 'boolean'),
		options = opt(command.options, checkArray, checkOption),
	}
end

local function checkCommandUpdate(command)
	checkType('table', command)
	return {
		name = opt(command.name, checkType, 'string'),
		description = opt(command.description, checkType, 'string'),
		default_permission = opt(command.defaultPermission, checkType, 'boolean'),
		options = opt(command.options, checkArray, checkOption),
	}
end

local function checkMessage(message, defaultAllowedMentions)
	checkType('table', message)
	checkType('table', defaultAllowedMentions)
	return {
		content = parseContent(message),
		embeds = parseEmbeds(message),
		allowed_mentions = parseAllowedMentions(message, defaultAllowedMentions),
		flags = opt(message.flags, checkBitfield),
		tts = opt(message.tts, checkType, 'boolean'),
	}, parseFiles(message)
end

local function checkMessageUpdate(message, defaultAllowedMentions)
	checkType('table', message)
	checkType('table', defaultAllowedMentions)
	return {
		content = parseContent(message),
		embeds = parseEmbeds(message),
		allowed_mentions = parseAllowedMentions(message, defaultAllowedMentions),
	}, parseFiles(message)
end

-- TODO: maybe inject and use application_id from auth/ready
-- TODO: maybe Application or Guild methods
-- TODO: more Interaction abstractions
-- TODO: permissions

function Client:getGlobalApplicationCommand(applicationId, commandId)
	applicationId = checkSnowflake(applicationId)
	commandId = checkSnowflake(commandId)
	local data, err = self.api:getGlobalApplicationCommand(applicationId, commandId)
	if data then
		return self.state:newCommand(data)
	else
		return nil, err
	end
end

function Client:getGlobalApplicationCommands(applicationId)
	applicationId = checkSnowflake(applicationId)
	local data, err = self.api:getGlobalApplicationCommands(applicationId)
	if data then
		return self.state:newCommands(data)
	else
		return nil, err
	end
end

function Client:createGlobalApplicationCommand(applicationId, payload)
	applicationId = checkSnowflake(applicationId)
	payload = checkCommand(payload)
	local data, err = self.api:createGlobalApplicationCommand(applicationId, payload)
	if data then
		return self.state:newCommand(data)
	else
		return nil, err
	end
end

function Client:editGlobalApplicationCommand(applicationId, commandId, payload)
	applicationId = checkSnowflake(applicationId)
	commandId = checkSnowflake(commandId)
	payload = checkCommandUpdate(payload)
	local data, err = self.api:editGlobalApplicationCommand(applicationId, commandId, payload)
	if data then
		return self.state:newCommand(data)
	else
		return nil, err
	end
end

function Client:deleteGlobalApplicationCommand(applicationId, commandId)
	applicationId = checkSnowflake(applicationId)
	commandId = checkSnowflake(commandId)
	local data, err = self.api:deleteGlobalApplicationCommand(applicationId, commandId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:bulkOverwriteGlobalApplicationCommands(applicationId, payload)
	applicationId = checkSnowflake(applicationId)
	payload = checkArray(checkCommand, payload)
	local data, err = self.api:bulkOverwriteGlobalApplicationCommands(applicationId, payload)
	if data then
		return self.state:newCommands(data)
	else
		return nil, err
	end
end

----

function Client:getGuildApplicationCommand(applicationId, guildId, commandId)
	applicationId = checkSnowflake(applicationId)
	guildId = checkSnowflake(guildId)
	commandId = checkSnowflake(commandId)
	local data, err = self.api:getGuildApplicationCommand(applicationId, guildId, commandId)
	if data then
		return self.state:newCommand(data)
	else
		return nil, err
	end
end

function Client:getGuildApplicationCommands(applicationId, guildId)
	applicationId = checkSnowflake(applicationId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildApplicationCommands(applicationId, guildId)
	if data then
		return self.state:newCommands(data)
	else
		return nil, err
	end
end

function Client:createGuildApplicationCommand(applicationId, guildId, payload)
	applicationId = checkSnowflake(applicationId)
	guildId = checkSnowflake(guildId)
	payload = checkCommand(payload)
	local data, err = self.api:createGuildApplicationCommand(applicationId, guildId, payload)
	if data then
		return self.state:newCommand(data)
	else
		return nil, err
	end
end

function Client:editGuildApplicationCommand(applicationId, guildId, commandId, payload)
	applicationId = checkSnowflake(applicationId)
	guildId = checkSnowflake(guildId)
	commandId = checkSnowflake(commandId)
	payload = checkCommandUpdate(payload)
	local data, err = self.api:editGuildApplicationCommand(applicationId, guildId, commandId, payload)
	if data then
		return self.state:newCommand(data)
	else
		return nil, err
	end
end

function Client:deleteGuildApplicationCommand(applicationId, guildId, commandId)
	applicationId = checkSnowflake(applicationId)
	guildId = checkSnowflake(guildId)
	commandId = checkSnowflake(commandId)
	local data, err = self.api:deleteGuildApplicationCommand(applicationId, guildId, commandId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:bulkOverwriteGuildApplicationCommands(applicationId, guildId, payload)
	applicationId = checkSnowflake(applicationId)
	guildId = checkSnowflake(guildId)
	payload = checkArray(checkCommand, payload)
	local data, err = self.api:bulkOverwriteGlobalApplicationCommands(applicationId, guildId, payload)
	if data then
		return self.state:newCommands(data)
	else
		return nil, err
	end
end

----

function Client:createInteractionResponse(interactionId, interactionToken, payload)
	interactionId = checkSnowflake(interactionId)
	interactionToken = checkType('string', interactionToken)
	payload = checkType('table', payload)
	local message, files = checkMessage(payload.data, self.defaultAllowedMentions)
	local data, err = self.api:createInteractionResponse(interactionId, interactionToken, {
		type = checkEnum(enums.interactionResponseType, payload.type),
		data = message,
	}, nil, files)
	if data then
		return true
	else
		return false, err
	end
end

function Client:getOriginalInteractionResponse(applicationId, interactionToken)
	applicationId = checkSnowflake(applicationId)
	interactionToken = checkType('string', interactionToken)
	local data, err = self.api:getOriginalInteractionResponse(applicationId, interactionToken)
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:editOriginalInteractionResponse(applicationId, interactionToken, payload)
	applicationId = checkSnowflake(applicationId)
	interactionToken = checkType('string', interactionToken)
	local message, files = checkMessageUpdate(payload, self.defaultAllowedMentions)
	local data, err = self.api:editOriginalInteractionResponse(applicationId, interactionToken, message, nil, files)
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:deleteOriginalInteractionResponse(applicationId, interactionToken)
	applicationId = checkSnowflake(applicationId)
	interactionToken = checkType('string', interactionToken)
	local data, err = self.api:deleteOriginalInteractionResponse(applicationId, interactionToken)
	if data then
		return true -- 204
	else
		return false, err
	end
end

----

function Client:createFollowupMessage(applicationId, interactionToken, payload)
	applicationId = checkSnowflake(applicationId)
	interactionToken = checkType('string', interactionToken)
	checkType('table', payload)
	local message, files = checkMessage(payload, self.defaultAllowedMentions)
	local data, err = self.api:createFollowupMessage(applicationId, interactionToken, message, nil, files)
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:editFollowupMessage(applicationId, interactionToken, messageId, payload)
	applicationId = checkSnowflake(applicationId)
	interactionToken = checkType('string', interactionToken)
	messageId = checkSnowflake(messageId)
	local message, files = checkMessageUpdate(payload, self.defaultAllowedMentions)
	local data, err = self.api:editFollowupMessage(applicationId, interactionToken, messageId, message, nil, files)
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:deleteFollowupMessage(applicationId, interactionToken, messageId)
	applicationId = checkSnowflake(applicationId)
	interactionToken = checkType('string', interactionToken)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:deleteFollowupMessage(applicationId, interactionToken, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

return Client
