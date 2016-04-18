## Server
Extends the **Object** class. Servers, also known as Guilds, are a core component of Discord communication. Servers contain text channels and voice channels in which member may communicate with each other.

---

### Methods

#### `setName(name)`
- name - *string*

Sets the name of the server to the specified name. Must be 2 to 100 characters in length.

#### `setRegion(regionId)`
- regionId - *string*

Sets the region of the server using the specified region ID (us-east, london, frankfurt, etc).

#### `setIcon(icon)`

#### `setOwner(user)`

#### `setAfkChannel(channel)`

#### `setAfkTimeout(timeout)`

#### `leave()`

Causes the client's user to leave the server. The user can only rejoin with an appropriate invitation.

#### `delete()`

Permanently deletes the server.

*Warning:* This is cannot be undone!

#### `getBannedUsers()`
- Returns *table*

Builds a list of users banned from the server, index by user ID.

<!-- #### `getInvites()` -->

#### `banUser(user)`
- user - *User* or *Member* object

Kicks a user from the server and prevents them from rejoining. Discord bans are by IP address.

*Related:* `User:ban(server)`

#### `unbanUser(user)`
- user - *User* or *Member* object

Allows a previously banned user to rejoin the server. The user can only rejoin with an appropriate invitation.

*Related:* `User:unban(server)`

#### `kickUser(user)`
- user - *User* or *Member* object

Kicks a user from the server. The user can only rejoin with an appropriate invitation.

*Related:* `User:kick(server)`

#### `getRoleById(id)`
- id - *string*
- Returns *Role* or *nil*

Returns a locally cached *Role* object that has the provided ID, or *nil* if none is found.

*Related:* `Client:getRoleById(id)`

#### `getRoleByName(id)`
- name - *string*
- Returns *Role* or *nil*

Returns a locally cached *Role* object that has the provided name. Since more than one role can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

*Related:* `Client:getRoleByName(name)`

<!-- #### `createRole(name)` -->

#### `createTextChannel(name)`
- name - *string*
- Returns *ServerTextChannel*

Creates a text channel with the specified name. The *ServerTextChannel* object returned is not the same object as that which is later cached or emitted with the *channelCreate* event.

#### `createVoiceChannel(name)`
- name - *string*
- Returns *ServerVoiceChannel*

Creates a voice channel with the specified name. The *ServerVoiceChannel* object returned is not the same object as that which is later cached or emitted with the *channelCreate* event.

#### `getChannelById(id)`
- id - *string*
- Returns *ServerChannel* or *nil*

Returns a locally cached *ServerChannel* object that has the provided ID, or *nil* if none is found.

*Related:* `Client:getChannelById(id)`

#### `getChannelByName(name)`
- name - *string*
- Returns *ServerChannel* or *nil*

Returns a locally cached *ServerChannel* object that has the provided name. Since more than one channel can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

*Related:* `Client:getChannelByName(name)`

#### `getTextChannelByName(name)`
- name - *string*
- Returns *ServerTextChannel* or *nil*

Returns a locally cached *ServerTextChannel* object that has the provided name. Since more than one channel can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

#### `getVoiceChannelByName(name)`
- name - *string*
- Returns *ServerVoiceChannel* or *nil*

Returns a locally cached *ServerVoiceChannel* object that has the provided name. Since more than one channel can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

#### `getMemberById(id)`
- id - *string*
- Returns *Member* or *nil*

Returns a locally cached server *Member* object that has the provided ID, or *nil* if none is found.

*Related:* `Client:getMemberById(id)`

#### `getMemberByName(name)`
- name - *string*
- Returns *Member* or *nil*

Returns a locally cached server *Member* object that has the provided name. Since more than one member can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

*Related:* `Client:getMemberByName(name)`

#### `getMessageById(id)`
- id - *string*
- Returns *Message* or *nil*

Returns a locally cached *Message* object that has the provided ID, or *nil* if none is found.

*Related:* `Client:getMessageById(id)` `Channel:getMessageById(id)`

---

### Properties

#### `id`
*String* representing the unique snowflake ID of the server.

#### `client`
*Client* object representing the Discord client that is aware of the server.

#### `name`
*String* representing the server's name. Edit with `Server:setName(name)`.

#### `icon`
*String* representing the server's icon

#### `regionId`
*String* representing the server's region ID. Edit with `Server:setRegion(regionId)`.

#### `owner`
*Member* object representing the server's owner. Edit with `Server:setOwner(user)`

#### `afkTimeout`

#### `afkChannel`

#### `embedEnabled`

#### `embedChannelId`
???

#### `verificationLevel`

#### `large`

#### `joinedAt`

#### `memberCount`

#### `roles`

#### `members`

#### `channels`

#### `voiceStates`
