# Discordia With Buttons
A slightly modified version of [SinisterRectus's Discordia](https://www.github.com/SinisterRectus/Discordia) to add support for buttons.

Thanks to:
- [Bilal2453](https://www.github.com/Bilal2453/), for his coro-http documentation
- [advaith](https://www.github.com/advaith1), for his help in figuring out acknowledgments
- All contributors of the original Discordia repository

## Adding Buttons
You can add a button to a message like so:
```lua
message.channel:send {
    content = "Hello world!", -- Content besides the button is required. This content can be text, embeds, files, etc.
    components = {
        {
            type = 1,
            components = {
                {
                    type = 2,
                    style = 1,
                    label = "Test Button",
                    custom_id = "test_button",
                    disabled = false
                }
            }
        }
    }
}
```

See [Discord's documentation](https://discord.com/developers/docs/interactions/message-components) for more details.

## Using Buttons
You can use buttons by listening for the `buttonPressed` event.

The event passes three arguments:
- `buttonid` - the custom id of the button that was pressed
- `member` - the member who pressed the button
- `message` - the message the button belongs to

E.g.,
```lua
client:on("buttonPressed", function(buttonid, member, message)
	-- do stuff
end)
```

## The Message Object
This fork also adds a few properties to the message object.
- `components` - the raw components table
- `buttons` - a table of buttons
- `button` - the first button

### Example Components Table:
```lua
{ 
	{
		type = 1, 
		components = {
			{type = 2, custom_id = 'test_button_1', style = 1, label = 'Testing 1'}, 
			{type = 2, custom_id = 'test_button_2', style = 2, label = 'Testing 2'} 
		} 
	} 
}
```

### Example Buttons Table
```lua
{
	{type = 2, custom_id = 'test_button_1', style = 1, label = 'Testing 1'}, 
	{type = 2, custom_id = 'test_button_2', style = 2, label = 'Testing 2'} 
} 
```

### Example Button Table
```lua
{
	type = 2,
	custom_id = 'test_button_2',
	style = 2,
	label = 'Testing 2'
} 
```

## Warning
This fork is a quick and dirty implementation of buttons. Because slash-commands use the same event, `INTERACTION_CREATE`, using them along with buttons may break your buttons, slash-commands, or both. Use with caution.
