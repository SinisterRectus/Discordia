Probable additions
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
- getMessageHistory before/after
- implement role creation
- return more values

Possible additions
- Change Client to use custom class
- Iterators for things like getServers
- Implement private/public attributes
- Cache objects
- Helper functions, like find, findAll, getMembersWithRole, ...
- Dynamically generate object properties from data?
  - Rather than parse the data on object creation, parse it only when the object is accessed

Fixes Needed
- Make delayed ready event more explicit
- Fix voice state count
- Fix game updating
- Consider changing ban events to handle User objects, not Members
- Allow users to set roles via object methods
- Account for (or remove) channel mentions in private messages
- check that table.deepcount is accurate
- enhance permissions abstraction
- fix member roles not being updated
