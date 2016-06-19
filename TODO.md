Probable additions
- Add a REST client that handles most, if not all, REST methods.
	- Can use for methods like Client:sendMessage(channelId, content) when only the IDs are known.
	- Can be called by methods like Channel:sendMessage(content) when the objects exist.
	- Can be used with getObjectById when the object is not cached.
	- Better rate limiting
	- Error codes
- Handle USER_SETTINGS_UPDATE
- Handle MESSAGE_BULK_DELETE
- Move Server/Channel/Role positions
- Embeds and file sharing
- Sharding
- Optional Client init args (max messages, grab initial messages, auto reconnect, auto retry, max retries, default date format, toggle caching)
- Change Server to Guild
- Get server icon
- Implement Game object
- Twitch streaming url
- Utilities for iterating/searching/finding objects
- Logging support

Possible additions
- Change Client to use custom class
- Iterators for things like getServers
- Implement private/public attributes
- Cache objects
- Helper functions, like find, findAll, getMembersWithRole, ...
- Dynamically generate object properties from data?
  - Rather than parse the data on object creation, parse it only when the object is accessed
  - Use sequentially index properties hack

Fixes Needed
- Make delayed ready event more explicit
- Fix voice state count
- Fix game updating
- Consider changing ban events to handle User objects, not Members
- Allow users to set roles via object methods
