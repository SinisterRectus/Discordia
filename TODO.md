Probable additions
- API calls need to be exposed to invididual classes
- Message mentions, embeds, and attachments
- File sharing
- Sharding
- Twitch streaming url
- Logging support
- Guild emojis and features
- Remove os.exit from client:stop()
- Provide old user object on presenceUpdate (maybe other events)
- Pinned message getting
- User friendly permissions

Possible additions
- Implement Game object
- Handle USER_SETTINGS_UPDATE and USER_GUILD_SETTINGS_UPDATE
- Change Client to use custom class
- Implement private/public attributes
- Helper functions, like getMembersWithRole, ...
- Make ready timeout relative to guild loading
- Voice support

Fixes Needed
- Check for json null values on user object in presence update
