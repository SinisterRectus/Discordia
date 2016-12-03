--[[
This is a test for Discordia's rate limit handling.
Insert your own token and channel ID below.
Please make sure that the account has permissions to send messages,
create invites, and add reactions in the indicated channel.
]]

---- config --------------------------------------------------------------------
local TOKEN = ''
local CHANNEL_ID = ''
--------------------------------------------------------------------------------

local discordia = require('discordia')
local timer = require('timer')

local sleep = timer.sleep
local wrap = coroutine.wrap

local function async(fn, ...)
	return wrap(fn)(...)
end

local client = discordia.Client()

client:on('ready', function()

	printf('Logged in as %s', client.user.username)
	local channel = client:getTextChannel(CHANNEL_ID)
	assert(channel, 'Could not find channel: ' .. CHANNEL_ID)

	print('\nRunning synchronous, same route, test...')
	for i = 1, 6 do
		printf('sending message %i', i)
		printf('message %i sent', channel:sendMessage(i).content)
	end

	print('\nRunning asynchronous, same route, test...')
	for i = 1, 6 do
		printf('sending message %i', i)
		async(function()
			printf('message %i sent', channel:sendMessage(i).content)
		end)
	end

	sleep(8000)

	async(function()

		print('\nRunning synchronous, multi-route test...')

		print('creating invite')
		local invite = channel:createInvite()
		print('invite created', invite)
		print('deleting invite')
		print('invite deleted', invite:delete())

		print('sending message')
		local message = channel:sendMessage('sync test')
		print('message created', message)
		print('adding reaction')
		print('reaction added', message:addReaction('👍'))
		print('removing reaction')
		print('reaction removed', message:removeReaction('👍'))
		print('deleting message')
		print('message deleted', message:delete())

		print('\nRunning asynchronous, multi-route test...')

		local a, b, c

		async(function()
			print('creating invite')
			local invite = channel:createInvite()
			print('invite created', invite)
			print('deleting invite')
			print('invite deleted', invite:delete())
			a = true
		end)

		async(function()
			print('sending message')
			local message = channel:sendMessage('async test 1')
			print('message created', message)
			print('adding reaction')
			print('reaction added', message:addReaction('👍'))
			print('removing reaction')
			print('reaction removed', message:removeReaction('👍'))
			print('deleting message')
			print('message deleted', message:delete())
			b = true
		end)

		async(function()
			print('sending message')
			local message = channel:sendMessage('async test 2')
			print('message created', message)
			print('adding reaction')
			print('reaction added', message:addReaction('👎'))
			print('removing reaction')
			print('reaction removed', message:removeReaction('👎'))
			print('deleting message')
			print('message deleted', message:delete())
			c = true
		end)

		timer.setInterval(1000, function()
			if a and b and c then
				print('\nTest completed.')
				async(client.stop, client, true)
			end
		end)

	end)

end)

async(function()

	print('\nRunning mutex test...')
	require('uv').update_time()

	local sw = discordia.Stopwatch()
	local t = 1000

	print('\nRunning coroutines without a mutex...')

	async(function()
		print('Starting coroutine 1')
		sleep(t)
		printf('Coroutine 1. This should print 3rd, after %i ms (actual: %i ms).', t, sw.milliseconds)
	end)

	async(function()
		print('Starting coroutine 2')
		sleep(t / 10)
		printf('Coroutine 2. This should print 2rd, after %i ms (actual: %i ms).', t / 10, sw.milliseconds)
	end)

	async(function()
		print('Starting coroutine 3')
		sleep(t / 100)
		printf('Coroutine 3. This should print 1st, after %i ms (actual: %i ms).', t / 100, sw.milliseconds)
	end)

	sleep(t * 1.2)

	local mutex = discordia.Mutex()
	sw:restart()

	printf('\nRunning coroutines with a mutex...')

	async(function()
		print('Starting coroutine 4')
		mutex:lock()
		sleep(t)
		printf('Coroutine 4. This should print 1st, after %i ms (actual: %i ms).', t, sw.milliseconds)
		mutex:unlock()
	end)

	async(function()
		print('Starting coroutine 5')
		mutex:lock()
		sleep(t / 10)
		printf('Coroutine 5. This should print 2rd, after %i ms (actual: %i ms).', 11 * t / 10, sw.milliseconds)
		mutex:unlock()
	end)

	async(function()
		print('Starting coroutine 6')
		mutex:lock()
		sleep(t / 100)
		printf('Coroutine 6. This should print 3rd, after %i ms (actual: %i ms).', 111 * t / 100, sw.milliseconds)
		mutex:unlock()
	end)

	sleep(t * 1.2)

	print('\nRunning Discord test...')

	client:run(TOKEN)

end)
