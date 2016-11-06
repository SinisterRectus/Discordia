require('./discordia')
local fs = require('fs')

local path = '../Discordia.wiki/classes'
fs.mkdirSync(path)

local classes = class.__classes

local open = io.open
local max = math.max
local floor, ceil = math.floor, math.ceil
local insert, sort = table.insert, table.sort
local f, rep, upper = string.format, string.rep, string.upper

local tmp = io.tmpfile()
local mt = getmetatable(tmp)

function mt.writef(self, ...)
	return self:write(f(...))
end

function mt.writeln(self, str)
	return self:write(str .. '\n')
end

function mt.writefln(self, ...)
	return self:write(f(...) .. '\n')
end

tmp:close()

local function actualClass(type, class, name)
	for _, base in ipairs(class.__bases) do
		if base[type][name] then
			return actualClass(type, base, name)
		end
	end
	return class
end

local function padRight(str, len)
	return str .. rep(' ', len - #str)
end

local function padCenter(str, len)
	local pad = 0.5 * (len - #str)
	return rep(' ', floor(pad)) .. str .. rep(' ', ceil(pad))
end

local writers = {}

function writers.__properties(file, properties)

	local longestName = 0
	local longestType = 0
	local longestDesc = 0

	for _, property in ipairs(properties) do
		longestName = max(longestName, #property[1])
		longestType = max(longestType, #property[2])
		longestDesc = max(longestDesc, #property[4])
	end

	file:writefln('| %s | %s | %s | %s |',
		padRight('Name', longestName),
		padRight('Type', longestType),
		'Mutable',
		padRight('Description', longestDesc)
	)

	file:writefln('| %s | %s |:%s:| %s |',
		rep('-', longestName),
		rep('-', longestType),
		rep('-', 7),
		rep('-', longestDesc)
	)

	for _, property in ipairs(properties) do
		local mutable = property[3] and 'X' or ''
		file:writefln('| %s | %s | %s | %s |',
			padRight(property[1], longestName),
			padRight(property[2], longestType),
			padCenter(mutable, 7),
			padRight(property[4], longestDesc)
		)
	end

end

function writers.__methods(file, methods)

	local longestName = 0
	local longestDesc = 0

	for _, method in ipairs(methods) do
		method[1] = f('%s(%s)', method[1], method[2])
		longestName = max(longestName, #method[1])
		longestDesc = max(longestDesc, #method[3])
	end

	file:writefln('| %s | %s |',
		padRight('Prototype', longestName),
		padRight('Description', longestDesc)
	)

	file:writefln('| %s | %s |',
		rep('-', longestName),
		rep('-', longestDesc)
	)

	for _, method in ipairs(methods) do
		file:writefln('| %s | %s |',
			padRight(method[1], longestName),
			padRight(method[3], longestDesc)
		)
	end

end

local sorter = function(a, b) return a[1] < b[1] end

local function writeDocs(file, class, type)

	local temp = {}
	local names = {}
	local inherited = {}

	for k, v in pairs(class[type]) do
		local entry
		if type == '__properties' then
			entry = {k, v[1], class.__setters[k], v[2]}
		elseif type == '__methods' then
			entry = {k, v[1], v[2]}
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

		if next(class.__caches) then
			local caches = {}
			for k in pairs(class.__caches) do
				insert(caches, k)
			end
			sort(caches)
			file:writeln('### Objects Accessible via [[Caches|Object caching]]')
			for _, v in ipairs(caches) do
				file:writefln('- %ss', v)
			end
			file:writeln('')
		end

		if next(class.__properties) then
			writeDocs(file, class, '__properties')
		end

		if next(class.__methods) then
			writeDocs(file, class, '__methods')
		end

		file:close()

	end

end
