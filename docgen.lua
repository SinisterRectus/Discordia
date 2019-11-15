--[=[
@i?c ClassName [x base_1 x base_2 ... x base_n]
@p parameterName type
@op optionalParameterName type
@d class description+
]=]

--[=[
@s?m methodName
@p parameterName type
@op optionalParameterName type
@r return
@d description+
]=]

--[=[
@p propertyName type description+
]=]

local fs = require('fs')
local pathjoin = require('pathjoin')

local insert, sort, concat = table.insert, table.sort, table.concat
local format = string.format
local pathJoin = pathjoin.pathJoin

local function scan(dir)
	for fileName, fileType in fs.scandirSync(dir) do
		local path = pathJoin(dir, fileName)
		if fileType == 'file' then
			coroutine.yield(path)
		else
			scan(path)
		end
	end
end

local function match(s, pattern) -- only useful for one capture
	return assert(s:match(pattern), s)
end

local function gmatch(s, pattern) -- only useful for one capture
	local tbl = {}
	for v in s:gmatch(pattern) do
		insert(tbl, v)
	end
	return tbl
end

local function matchType(s)
	return s:match('^@(%S+)')
end

local function matchComments(s)
	return s:gmatch('--%[=%[%s*(.-)%s*%]=%]')
end

local function matchClassName(s)
	return match(s, '@i?c (%S+)')
end

local function matchMethodName(s)
	return match(s, '@s?m (%S+)')
end

local function matchDescription(s)
	return match(s, '@d (.+)'):gsub('%s+', ' ')
end

local function matchParents(s)
	return gmatch(s, 'x (%S+)')
end

local function matchReturns(s)
	return gmatch(s, '@r (%S+)')
end

local function matchProperty(s)
	local a, b, c = s:match('@p (%S+) (%S+) (.+)')
	return {
		name = assert(a, s),
		type = assert(b, s),
		desc = assert(c, s):gsub('%s+', ' '),
	}
end

local function matchParameters(s)
	local ret = {}
	for optional, paramName, paramType in s:gmatch('@(o?)p (%S+) (%S+)') do
		insert(ret, {paramName, paramType, optional == 'o'})
	end
	return ret
end

local function matchMethod(s)
	return {
		name = matchMethodName(s),
		desc = matchDescription(s),
		parameters = matchParameters(s),
		returnTypes = matchReturns(s),
	}
end

----

local docs = {}

local function newClass()

	local class = {
		methods = {},
		statics = {},
		properties = {},
	}

	local function init(s, userInitialized)
		class.name = matchClassName(s)
		class.parents = matchParents(s)
		class.desc = matchDescription(s)
		class.parameters = matchParameters(s)
		class.userInitialized = userInitialized
		assert(not docs[class.name], 'duplicate class: ' .. class.name)
		docs[class.name] = class
	end

	return class, init

end

for f in coroutine.wrap(scan), './libs' do

	local d = assert(fs.readFileSync(f))

	local class, initClass = newClass()
	for s in matchComments(d) do
		local t = matchType(s)
		if t == 'c' then
			initClass(s)
		elseif t == 'ic' then
			initClass(s, true)
		elseif t == 'sm' then
			insert(class.statics, matchMethod(s))
		elseif t == 'm' then
			insert(class.methods, matchMethod(s))
		elseif t == 'p' then
			insert(class.properties, matchProperty(s))
		end
	end

end

----

local function link(str)
	local ret = {}
	for t in str:gmatch('[^/]+') do
		insert(ret, docs[t] and format('[[%s]]', t) or t)
	end
	return concat(ret, '/')
end

local function sorter(a, b)
	return a.name < b.name
end

local function writeProperties(f, properties)
	sort(properties, sorter)
	f:write('| Name | Type | Description |\n')
	f:write('|-|-|-|\n')
	for _, v in ipairs(properties) do
		f:write('| ', v.name, ' | ', link(v.type), ' | ', v.desc, ' |\n')
	end
end

local function writeParameters(f, parameters)
	f:write('(')
	local optional
	if parameters[1] then
		for i, param in ipairs(parameters) do
			f:write(param[1])
			if i < #parameters then
				f:write(', ')
			end
			if param[3] then
				optional = true
			end
		end
		f:write(')\n')
		if optional then
			f:write('>| Parameter | Type | Optional |\n')
			f:write('>|-|-|:-:|\n')
			for _, param in ipairs(parameters) do
				local o = param[3] and '✔' or ''
				f:write('>| ', param[1], ' | ', param[2], ' | ', o, ' |\n')
			end
		else
			f:write('>| Parameter | Type |\n')
			f:write('>|-|-|\n')
			for _, param in ipairs(parameters) do
				f:write('>| ', param[1], ' | ', link(param[2]), '|\n')
			end
		end
	else
		f:write(')\n')
	end
end

local function writeMethods(f, methods)
	sort(methods, sorter)
	for _, method in ipairs(methods) do
		f:write('### ', method.name)
		writeParameters(f, method.parameters)
		f:write('>\n>', method.desc, '\n>\n')
		local returns = {}
		for i, retType in ipairs(method.returnTypes) do
			returns[i] = link(retType)
		end
		f:write('>Returns: ', concat(returns, ', '), '\n\n')
	end
end

if not fs.existsSync('docs') then
	fs.mkdirSync('docs')
end

local function clean(input, seen)
	local fields = {}
	for _, field in ipairs(input) do
		if not seen[field.name] then
			insert(fields, field)
		end
	end
	return fields
end

for _, class in pairs(docs) do

	local seen = {}
	for _, v in pairs(class.properties) do seen[v.name] = true end
	for _, v in pairs(class.statics) do seen[v.name] = true	end
	for _, v in pairs(class.methods) do seen[v.name] = true	end

	local f = io.open(pathJoin('docs', class.name .. '.md'), 'w')

	if next(class.parents) then
		f:write('#### *extends ', '[[', concat(class.parents, ']], [['), ']]*\n\n')
	end

	f:write(class.desc, '\n\n')

	if class.userInitialized then
		f:write('## Constructor\n\n')
		f:write('### ', class.name)
		writeParameters(f, class.parameters)
		f:write('\n')
	else
		f:write('*Instances of this class should not be constructed by users.*\n\n')
	end

	for _, parent in ipairs(class.parents) do
		if docs[parent] and next(docs[parent].properties) then
			local properties = docs[parent].properties
			if next(properties) then
				f:write('## Properties Inherited From ', link(parent), '\n\n')
				writeProperties(f, clean(properties, seen))
			end
		end
	end

	if next(class.properties) then
		f:write('## Properties\n\n')
		writeProperties(f, class.properties)
	end

	for _, parent in ipairs(class.parents) do
		if docs[parent] and next(docs[parent].statics) then
			local statics = docs[parent].statics
			if next(statics) then
				f:write('## Static Methods Inherited From ', link(parent), '\n\n')
				writeMethods(f, clean(statics, seen))
			end
		end
	end

	for _, parent in ipairs(class.parents) do
		if docs[parent] and next(docs[parent].methods) then
			local methods = docs[parent].methods
			if next(methods) then
				f:write('## Methods Inherited From ', link(parent), '\n\n')
				writeMethods(f, clean(methods, seen))
			end
		end
	end

	if next(class.statics) then
		f:write('## Static Methods\n\n')
		writeMethods(f, class.statics)
	end

	if next(class.methods) then
		f:write('## Methods\n\n')
		writeMethods(f, class.methods)
	end

	f:close()

end
