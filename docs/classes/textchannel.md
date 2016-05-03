## ServerChannel
Extends the `Base` class. `TextChannel` is an abstract class representing channels that can be used for text communication. It is a superclass of two different subclasses: `ServerTextChannel` and `PrivateChannel`. Since all private channels are text channels, there is no "PrivateTextChannel" class.

---

### Methods

#### `createMessage(content)` -> `Message`
- content - string

This creates a text message and presents it in the channel to be viewed. The `Message` object returned is not the same object as that which is later cached or emitted with the `messageCreate` event.

#### `sendMessage(content)` -> `Message`
- content - string

An alias for `createMessage`.

#### `getMessageHistory()` - > `table`
Returns a table of the previous 50 messages in the channel. The table is a sequentially indexed table of `Message` objects; it is not indexed by object ID. The objects are also not cached, nor are they sourced from any local cache, they are grabbed from Discord's servers, so use sparingly, and cache the results manually.

#### `getMessageById(id)` - > `Message`
Returns a locally cached `Message` object that has the provided ID, or `nil` if none is found. Note that the message may not be known to the client if its creation was not witnessed while the client was logged in.

### Properties

#### `id`
String representing the unique snowflake ID of the channel.

#### `client`
Client object representing the Discord client that is aware of the channel.

#### `isPrivate`
Boolean representing whether the channel is a private channel.

#### `messages`
Table of cached `Message` objects that are known to the client.

#### `deque`
Deque object that keeps an ordered list of `Message` objects. Essentially an alias of `messages`, index sequentially rather than by message ID. Emptying of the deque depends upon Client.maxMessages.
