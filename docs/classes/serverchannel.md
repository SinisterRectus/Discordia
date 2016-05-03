## ServerChannel
Extends the `Base` class. `ServerChannel` is an abstract class representing channels that are associated with Discord servers. It is a superclass of two different subclasses: `ServerTextChannel` and `ServerVoiceChannel`.

---

### Methods

#### `setName(name)`
- name - string

Sets the name of the channel to the specified name. Must be 2 to 100 characters in length.

#### `createInvite()` -> `Invite`
Creates an invitation to the channel using default options, and returns an `Invite` object.

#### `getInvites()` -> `table`
Returns a table of `Invite` objects associated with the target channel.

#### `delete()`
Permanently deletes the channel.

*Warning:* This is cannot be undone!

### Properties

#### `id`
String representing the unique snowflake ID of the channel.

#### `client`
Client object representing the Discord client that is aware of the channel.

#### `name`
String representing the channel's name.

#### `topic`
String representing the channel's topic.

#### `type`
String representing the channel's type. Can be either `text` or `voice`.

#### `position`
Number representing the channel's position in the line-up of channels, visible on the default Discord client.
