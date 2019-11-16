--[=[
@c Invite x Container
@d Represents an invitation to a Discord guild channel. Invites can be used to join
a guild, though they are not always permanent.
]=]

local Container = require('containers/abstract/Container')
local json = require('json')

local format = string.format
local null = json.null

local function load(v)
	return v ~= null and v or nil
end

local Invite, get = require('class')('Invite', Container)

function Invite:__init(data, parent)
	Container.__init(self, data, parent)
	self._guild_id = load(data.guild.id)
	self._channel_id = load(data.channel.id)
	self._guild_name = load(data.guild.name)
	self._guild_icon = load(data.guild.icon)
	self._guild_splash = load(data.guild.splash)
	self._guild_banner = load(data.guild.banner)
	self._guild_description = load(data.guild.description)
	self._guild_verification_level = load(data.guild.verification_level)
	self._channel_name = load(data.channel.name)
	self._channel_type = load(data.channel.type)
	if data.inviter then
		self._inviter = self.client._users:_insert(data.inviter)
	end
end

--[=[
@m __hash
@r string
@d Returns `Invite.code`
]=]
function Invite:__hash()
	return self._code
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the invite. This cannot be undone!
]=]
function Invite:delete()
	local data, err = self.client._api:deleteInvite(self._code)
	if data then
		return true
	else
		return false, err
	end
end

--[=[@p code string The invite's code which can be used to identify the invite.]=]
function get.code(self)
	return self._code
end

--[=[@p guildId string The Snowflake ID of the guild to which this invite belongs.]=]
function get.guildId(self)
	return self._guild_id
end

--[=[@p guildName string The name of the guild to which this invite belongs.]=]
function get.guildName(self)
	return self._guild_name
end

--[=[@p channelId string The Snowflake ID of the channel to which this belongs.]=]
function get.channelId(self)
	return self._channel_id
end

--[=[@p channelName string The name of the channel to which this invite belongs.]=]
function get.channelName(self)
	return self._channel_name
end

--[=[@p channelType number The type of the channel to which this invite belongs. Use the `channelType`
enumeration for a human-readable representation.]=]
function get.channelType(self)
	return self._channel_type
end

--[=[@p guildIcon string/nil The hash for the guild's custom icon, if one is set.]=]
function get.guildIcon(self)
	return self._guild_icon
end

--[=[@p guildBanner string/nil The hash for the guild's custom banner, if one is set.]=]
function get.guildBanner(self)
	return self._guild_banner
end

--[=[@p guildSplash string/nil The hash for the guild's custom splash, if one is set.]=]
function get.guildSplash(self)
	return self._guild_splash
end

--[=[@p guildIconURL string/nil The URL that can be used to view the guild's icon, if one is set.]=]
function get.guildIconURL(self)
	local icon = self._guild_icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._guild_id, icon) or nil
end

--[=[@p guildBannerURL string/nil The URL that can be used to view the guild's banner, if one is set.]=]
function get.guildBannerURL(self)
	local banner = self._guild_banner
	return banner and format('https://cdn.discordapp.com/banners/%s/%s.png', self._guild_id, banner) or nil
end

--[=[@p guildSplashURL string/nil The URL that can be used to view the guild's splash, if one is set.]=]
function get.guildSplashURL(self)
	local splash = self._guild_splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._guild_id, splash) or nil
end

--[=[@p guildDescription string/nil The guild's custom description, if one is set.]=]
function get.guildDescription(self)
	return self._guild_description
end

--[=[@p guildVerificationLevel number/nil The guild's verification level, if available.]=]
function get.guildVerificationLevel(self)
	return self._guild_verification_level
end

--[=[@p inviter User/nil The object of the user that created the invite. This will not exist if the
invite is a guild widget or a vanity invite.]=]
function get.inviter(self)
	return self._inviter
end

--[=[@p uses number/nil How many times this invite has been used. This will not exist if the invite is
accessed via `Client:getInvite`.]=]
function get.uses(self)
	return self._uses
end

--[=[@p maxUses number/nil The maximum amount of times this invite can be used. This will not exist if the
invite is accessed via `Client:getInvite`.]=]
function get.maxUses(self)
	return self._max_uses
end

--[=[@p maxAge number/nil How long, in seconds, this invite lasts before it expires. This will not exist
if the invite is accessed via `Client:getInvite`.]=]
function get.maxAge(self)
	return self._max_age
end

--[=[@p temporary boolean/nil Whether the invite grants temporary membership. This will not exist if the
invite is accessed via `Client:getInvite`.]=]
function get.temporary(self)
	return self._temporary
end

--[=[@p createdAt string/nil The date and time at which the invite was created, represented as an ISO 8601
string plus microseconds when available. This will not exist if the invite is
accessed via `Client:getInvite`.]=]
function get.createdAt(self)
	return self._created_at
end

--[=[@p revoked boolean/nil Whether the invite has been revoked. This will not exist if the invite is
accessed via `Client:getInvite`.]=]
function get.revoked(self)
	return self._revoked
end

--[=[@p approximatePresenceCount number/nil The approximate count of online members.]=]
function get.approximatePresenceCount(self)
	return self._approximate_presence_count
end

--[=[@p approximateMemberCount number/nil The approximate count of all members.]=]
function get.approximateMemberCount(self)
	return self._approximate_member_count
end

return Invite
