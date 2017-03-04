require('./discordia')
local fs = require('fs')

local path = '../Discordia.wiki/classes'
fs.mkdirSync(path)

local classes = class.__classes

local open = io.open
local max = math.max
local insert, sort = table.insert, table.sort
local f, rep, upper = string.format, string.rep, string.upper
local padright, padcenter = string.padright, string.padcenter

local tmp = io.tmpfile()
local mt = getmetatable(tmp)

function mt:writef(...)
	return self:write(f(...))
end

function mt:writeln(str)
	return self:write(str, '\n')
end

function mt:writefln(...)
	return self:write(f(...), '\n')
end

tmp:close()

local function actualClass(type, class, name)
	for _, base in ipairs(class.__bases) do
		if base.__info[type][name] then
			return actualClass(type, base, name)
		end
	end
	return class
end

local writers = {}

function writers.properties(file, properties)

	local longestName = 0
	local longestType = 0
	local longestDesc = 0

	for _, property in ipairs(properties) do
		longestName = max(longestName, #property[1])
		longestType = max(longestType, #property[2])
		longestDesc = max(longestDesc, #property[4])
	end

	file:writefln('| %s | %s | %s | %s |',
		padright('Name', longestName),
		padright('Type', longestType),
		'Mutable',
		padright('Description', longestDesc)
	)

	file:writefln('| %s | %s |:%s:| %s |',
		rep('-', longestName),
		rep('-', longestType),
		rep('-', 7),
		rep('-', longestDesc)
	)

	for _, property in ipairs(properties) do
		file:writefln('| %s | %s | %s | %s |',
			padright(property[1], longestName),
			padright(property[2], longestType),
			padcenter(property[3] and 'X' or '', 7),
			padright(property[4], longestDesc)
		)
	end

end

function writers.methods(file, methods)

	local longestInt = 0
	local longestName = 0
	local longestDesc = 0

	for _, method in ipairs(methods) do
		method[1] = f('%s(%s)', method[1], method[2])
		longestName = max(longestName, #method[1])
		longestDesc = max(longestDesc, #method[3])
		longestInt = max(longestInt, #method[4])
	end

	file:writefln('| %s | %s | %s |',
		padright('Prototype', longestName),
		padright('Interface', longestInt),
		padright('Description', longestDesc)
	)

	file:writefln('| %s | %s | %s |',
		rep('-', longestName),
		rep('-', longestInt),
		rep('-', longestDesc)
	)

	for _, method in ipairs(methods) do
		file:writefln('| %s | %s | %s |',
			padright(method[1], longestName),
			padright(method[4], longestInt),
			padright(method[3], longestDesc)
		)
	end

end

local sorter = function(a, b) return a[1] < b[1] end

local function writeDocs(file, class, type)

	local temp = {}
	local names = {}
	local inherited = {}

	for k, v in pairs(class.__info[type]) do
		local entry
		if type == 'properties' then
			entry = {k, v[1], class.__info.setters[k], v[2]}
		elseif type == 'methods' then
			entry = {k, v[1], v[2], v[3]}
		end
		local actual = actualClass(type, class, k)
		if actual ~= class then
			actual = actual.__name
			temp[actual] = temp[actual] or {}
			insert(temp[actual], entry)
		else
			insert(names, entry)
		end
		sort(names, sorter)
	end

	for k, v in pairs(temp) do
		insert(inherited, {k, v})
	end
	sort(inherited, sorter)

	local title = type:gsub('__', ''):gsub('^.', upper)

	if #inherited > 0 then
		for _, v in ipairs(inherited) do
			file:writefln('### %s Inherited From [[%s]]', title, v[1])
			sort(v[2], sorter)
			writers[type](file, v[2])
			file:writeln('')
		end
	end

	if #names > 0 then
		file:writeln('### Class ' .. title)
		writers[type](file, names)
		file:writeln('')
	end

end

for name, class in pairs(classes) do

	if class.__description then

		local file = open(f('%s/%s.md', path, name), 'w')
		file:writefln('#### %s', class.__description)
		file:writeln('')

		if next(class.__info.caches) then
			local caches = {}
			for k in pairs(class.__info.caches) do
				insert(caches, k)
			end
			sort(caches)
			file:writeln('### Objects Accessible via [[Caches|Object caching]]')
			for _, v in ipairs(caches) do
				file:writefln('- %ss', v)
			end
			file:writeln('')
		end

		if next(class.__info.properties) then
			writeDocs(file, class, 'properties')
		end

		if next(class.__info.methods) then
			writeDocs(file, class, 'methods')
		end

		file:close()

	end

end
