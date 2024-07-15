local Iterable = require('../libs/utils/Iterable')
local utils = require('./utils')

local assertEqual = utils.assertEqual

local arr = {
	{name = 'cow', sound = 'moo', color = 'black'},
	{name = 'cat', sound = 'meow', color = 'black'},
	{name = 'dog', sound = 'woof', color = 'white'},
}

local it = Iterable(arr, 'name')

assertEqual(#it, 3)

local cow = it:get(1)
assertEqual(cow.sound, 'moo')
assertEqual(cow.color, 'black')
assertEqual(cow, it:get('cow'))

for k, v in pairs(it) do
	assertEqual(k, 'cow')
	assertEqual(v, cow)
	break
end

for i, v in ipairs(it) do
	assertEqual(i, 1)
	assertEqual(v, cow)
	break
end

it:sort(function(a, b) return a.name < b.name end)

local cat = it:get(1)
assertEqual(cat.sound, 'meow')
assertEqual(cat.color, 'black')
assertEqual(cat, it:get('cat'))

for k, v in pairs(it) do
	assertEqual(k, 'cat')
	assertEqual(v, cat)
	break
end

for i, v in ipairs(it) do
	assertEqual(i, 1)
	assertEqual(v, cat)
	break
end

assertEqual(it:count(function(a) return a.color == 'black' end), 2)
assertEqual(it:find(function(a) return a.sound == 'woof' end).sound, 'woof')
assertEqual(#it:filter(function(a) return a.color == 'white' end), 1)

assertEqual(it:toArray()[1], cat)
assertEqual(it:toTable().cow, cow)

local data = it:select('name', 'sound', 'color')
assertEqual(data[1][1], 'cat')
assertEqual(data[2][2], 'moo')
assertEqual(data[3][3], 'white')