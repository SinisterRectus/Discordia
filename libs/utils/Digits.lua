local DEFAULT_BASE = 10

local codec = setmetatable({}, {__index = function(_, k) return k end})
for n, char in ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('()(.)') do
	codec[n - 1] = char
end

local bitops = {
	['AND'] = function(a, b) return a == 1 and b == 1 end,
	['OR'] = function(a, b) return a == 1 or b == 1 end,
	['XOR'] = function(a, b) return a ~= b end,
}

local prefixes = {
	['0b'] = 02, ['0B'] = 02,
	['0o'] = 08, ['0O'] = 08,
	['0x'] = 16, ['0X'] = 16,
}

-- "Digits" is a private class-like structure, not meant to be exposed publicly

local Digits = setmetatable({}, {__call = function(self, base)
	assert(type(base) == 'number' and base > 1)
	return setmetatable({base = base}, self)
end})

function Digits.isInstance(obj)
	return getmetatable(obj) == Digits
end

function Digits.positiveOne(base)
	local digits = Digits(base)
	digits[1] = 1
	return digits
end

function Digits.negativeOne(base)
	local digits = Digits(base)
	digits[1] = 1
	digits.sign = 1
	return digits
end

----

function Digits:__index(k)
	if type(k) == 'number' or k == 'sign' then
		return 0
	else
		return Digits[k]
	end
end

function Digits:copy()
	local copy = {}
	for k, v in pairs(self) do
		copy[k] = v
	end
	return setmetatable(copy, Digits)
end

function Digits:trim()
	local i = #self
	while i > 0 and self[i] == 0 do
		self[i] = nil
		i = i - 1
	end
end

function Digits:fill(n)
	for i = 1, n do
		self[i] = self[i] or 0
	end
end

function Digits.compare(a, b) -- unsigned
	assert(a.base == b.base)
	local n, m = #a, #b
	if n < m then
		return true
	elseif n > m then
		return false
	end
	for i = n, 1, -1 do
		if a[i] < b[i] then
			return true
		elseif a[i] > b[i] then
			return false
		end
	end
	return nil
end

function Digits:setDigit(i, v)
	if v >= self.base then
		local n = math.floor(v / self.base)
		self[i + 1] = self[i + 1] + n
		self[i] = v - n * self.base
	elseif v < 0 then
		local n = math.ceil(-v / self.base)
		self[i + 1] = self[i + 1] - n
		self[i] = v + n * self.base
	else
		self[i] = v
	end
end

function Digits.getSum(a, b) -- unsigned
	assert(a.base == b.base)
	local c = Digits(a.base)
	for i = 1, math.max(#a, #b) do
		c:setDigit(i, c[i] + a[i] + b[i])
	end
	return c
end

function Digits.addInPlace(a, b) -- unsigned
	assert(a.base == b.base)
	for i = 1, math.max(#a, #b) do
		a:setDigit(i, a[i] + b[i])
	end
end

function Digits.getDifference(a, b) -- unsigned
	assert(a.base == b.base)
	local n, m = #a, #b
	assert(n >= m)
	local c = Digits(a.base)
	for i = 1, n do
		c:setDigit(i, c[i] + a[i] - b[i])
	end
	c:trim()
	return c
end

function Digits.subtractInPlace(a, b) -- unsigned
	assert(a.base == b.base)
	local n, m = #a, #b
	assert(n >= m)
	for i = 1, n do
		a:setDigit(i, a[i] - b[i])
	end
	a:trim()
end

function Digits.getProduct(a, b) -- unsigned
	assert(a.base == b.base)
	local c = Digits(a.base)
	for i = 1, #a do
		for j = 1, #b do
			local k = i + j - 1
			c:setDigit(k, c[k] + a[i] * b[j])
		end
	end
	return c
end

function Digits:getComplement(n)
	assert(self.base == 2)
	local complement = Digits(2)
	for i = 1, n do
		complement[i] = math.abs(self[i] - 1)
	end
	Digits.addInPlace(complement, Digits.positiveOne(2))
	return complement
end

local function complementInPlace(digits, n)
	assert(digits.base == 2)
	for i = 1, n do
		digits[i] = math.abs(digits[i] - 1)
	end
	Digits.addInPlace(digits, Digits.positiveOne(2))
end

function Digits.bitop(a, b, k)

	assert(a.base == 2)
	assert(b.base == 2)
	local fn = assert(bitops[k])
	local n = math.max(#a, #b)
	local signed = fn(a.sign, b.sign)

	if a.sign == 1 then
		a = a:getComplement(n)
	end

	if b.sign == 1 then
		b = b:getComplement(n)
	end

	local c = Digits(a.base)
	for i = 1, n do
		c[i] = fn(a[i], b[i]) and 1 or 0
	end

	if signed then
		complementInPlace(c, n)
		c.sign = 1
	end

	c:trim()
	return c

end

----

local function parseUnsigned(n, base)
	local digits = Digits(base)
	while n > 0 do
		local r = n % base
		table.insert(digits, r)
		n = (n - r) / base
	end
	return digits
end

function Digits.fromNumber(n, base)
	local sign = nil
	if n < 0 then
		sign = 1
		n = -n
	end
	local digits = parseUnsigned(n, base)
	digits.sign = sign
	return digits
end

local function checkDigit(str, i, base)
	local digit = tonumber(str:sub(i, i), base)
	if not digit then
		return error('invalid number format: ' .. str)
	end
	return digit
end

function Digits.fromString(str, inputBase, outputBase) -- BE string to LE array

	local digits = Digits(outputBase)

	local a, b = 1, #str

	local _, j = str:find('^%s+', a)
	if j then a = j + 1 end -- ignore leading whitespace

	local k = str:find('%s+$', a)
	if k then b = k - 1 end -- ignore trailing whitespace

	-- consume sign
	local sign = str:sub(a, a)
	if sign == '-' then
		sign = 1
		a = a + 1
	elseif sign == '+' then
		sign = nil
		a = a + 1
	else
		sign = nil
	end

	if not inputBase then -- define inputBase
		local prefix = prefixes[str:sub(a, a + 1)]
		if prefix then
			inputBase = prefix
			a = a + 2
		else
			inputBase = DEFAULT_BASE
		end
	end

	local _, z = str:find('^0+', a)
	if z then a = z + 1 end -- ignore leading zeroes

	if inputBase == outputBase then
		for i = b, a, -1 do
			local digit = checkDigit(str, i, inputBase)
			table.insert(digits, digit)
		end
	else
		local base = parseUnsigned(inputBase, outputBase)
		for i = a, b, 1 do
			local digit = parseUnsigned(checkDigit(str, i, inputBase), outputBase)
			digits = digits:getProduct(base)
			digits:addInPlace(digit)
		end
	end

	digits.sign = #digits > 0 and sign or nil

	return digits

end

----

function Digits:convert(outputBase)
	local new = Digits(outputBase)
	local base = parseUnsigned(self.base, outputBase)
	for i = #self, 1, -1 do
		local digit = parseUnsigned(self[i], outputBase)
		new = new:getProduct(base)
		new:addInPlace(digit)
	end
	new.sign = rawget(self, 'sign')
	return new
end

function Digits:toString(outputBase, len)

	outputBase = outputBase or DEFAULT_BASE
	len = len or 1

	if self.base ~= outputBase then
		self = self:convert(outputBase)
	end

	local buf = {}

	if self.sign == 1 then
		table.insert(buf, '-')
	end

	for _ = 1, len - #self do
		table.insert(buf, '0')
	end

	for i = #self, 1, -1 do
		table.insert(buf, codec[self[i]])
	end

	return table.concat(buf)

end

function Digits:toNumber()
	local n = 0
	for i = #self, 1, -1 do
		n = n * self.base + self[i]
	end
	return self.sign == 1 and -n or n
end

return Digits