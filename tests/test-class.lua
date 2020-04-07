local class = require('../libs/class')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue
local assertFalse = utils.assertFalse
local assertNil = utils.assertNil
local assertError = utils.assertError

local Foo, Bar, Baz
local foo, bar, baz
local methods = {}
local getters = {}
local setters = {}

do
	function methods.testMixinMethod()
		return 'mixin-method'
	end
	function getters.testMixinGetter(self)
		return self._mixin_property
	end
	function setters.testMixinSetter(self, new)
		self._mixin_property = new
	end
end

do
	local get, set
	Foo, get, set = class('Foo', nil)
	class.mixin(Foo, methods)
	class.mixin(get, getters)
	class.mixin(set, setters)
	function Foo:__init()
		self._foo = 'foo'
		self._method_foo = 'method-foo'
		self._mixin_property = nil
	end
	function get:foo() return self._foo	end
	function set:foo(new) self._foo = new	end
	function Foo:getFoo() return self._method_foo end
	function Foo:setFoo(new) self._method_foo = new end
	function Foo:testFoo() self._undefined = 'test' end
	foo = Foo()
end

do
	local get, set
	Bar, get, set = class('Bar', Foo)
	function Bar:__init()
		Foo.__init(self)
		self._bar = 'bar'
		self._method_bar = 'method-bar'
		self._mixin_property = nil
	end
	function get:bar() return self._bar	end
	function set:bar(new) self._bar = new	end
	function Bar:getBar() return self._method_bar end
	function Bar:setBar(new) self._method_bar = new end
	function Bar:testBar() self._undefined = 'test' end
	bar = Bar()
end

do
	local get, set
	Baz, get, set = class('Baz', Bar)
	function Baz:__init()
		Bar.__init(self)
		self._baz = 'baz'
		self._method_baz = 'method-baz'
		self._mixin_property = nil
	end
	function get:baz() return self._baz	end
	function set:baz(new) self._baz = new	end
	function Baz:getBaz() return self._method_baz end
	function Baz:setBaz(new) self._method_baz = new end
	function Baz:testBaz() self._undefined = 'test' end
	baz = Baz()
end

assertEqual(tostring(Foo), 'class: Foo')
assertEqual(tostring(Bar), 'class: Bar')
assertEqual(tostring(Baz), 'class: Baz')

assertEqual(tostring(foo), 'object: Foo')
assertEqual(tostring(bar), 'object: Bar')
assertEqual(tostring(baz), 'object: Baz')

assertTrue(class.isClass(Foo))
assertTrue(class.isClass(Bar))
assertTrue(class.isClass(Baz))

assertTrue(class.isSubclass(Foo, Foo))
assertTrue(class.isSubclass(Bar, Bar))
assertTrue(class.isSubclass(Baz, Baz))

assertTrue(class.isSubclass(Bar, Foo))
assertTrue(class.isSubclass(Baz, Bar))
assertTrue(class.isSubclass(Baz, Foo))

assertFalse(class.isSubclass(Foo, Baz))
assertFalse(class.isSubclass(Foo, Bar))
assertFalse(class.isSubclass(Bar, Baz))

assertTrue(class.isObject(foo))
assertTrue(class.isObject(bar))
assertTrue(class.isObject(baz))

assertTrue(class.isInstance(foo, Foo))
assertTrue(class.isInstance(bar, Bar))
assertTrue(class.isInstance(baz, Baz))

assertTrue(class.isInstance(bar, Foo))
assertTrue(class.isInstance(baz, Bar))
assertTrue(class.isInstance(baz, Foo))

assertFalse(class.isInstance(foo, Baz))
assertFalse(class.isInstance(foo, Bar))
assertFalse(class.isInstance(bar, Baz))

assertEqual(foo.foo, 'foo')
assertEqual(bar.foo, 'foo')
assertEqual(bar.bar, 'bar')
assertEqual(baz.foo, 'foo')
assertEqual(baz.bar, 'bar')
assertEqual(baz.baz, 'baz')

assertEqual(foo:getFoo(), 'method-foo')
assertEqual(bar:getFoo(), 'method-foo')
assertEqual(bar:getBar(), 'method-bar')
assertEqual(baz:getFoo(), 'method-foo')
assertEqual(baz:getBar(), 'method-bar')
assertEqual(baz:getBaz(), 'method-baz')

foo.foo = 'new-foo'
bar.foo = 'new-foo'
bar.bar = 'new-bar'
baz.foo = 'new-foo'
baz.bar = 'new-bar'
baz.baz = 'new-baz'

assertEqual(foo.foo, 'new-foo')
assertEqual(bar.foo, 'new-foo')
assertEqual(bar.bar, 'new-bar')
assertEqual(baz.foo, 'new-foo')
assertEqual(baz.bar, 'new-bar')
assertEqual(baz.baz, 'new-baz')

foo:setFoo('new-method-foo')
bar:setFoo('new-method-foo')
bar:setBar('new-method-bar')
baz:setFoo('new-method-foo')
baz:setBar('new-method-bar')
baz:setBaz('new-method-baz')

assertEqual(foo:getFoo(), 'new-method-foo')
assertEqual(bar:getFoo(), 'new-method-foo')
assertEqual(bar:getBar(), 'new-method-bar')
assertEqual(baz:getFoo(), 'new-method-foo')
assertEqual(baz:getBar(), 'new-method-bar')
assertEqual(baz:getBaz(), 'new-method-baz')

assertEqual(foo:testMixinMethod(), 'mixin-method')
assertEqual(bar:testMixinMethod(), 'mixin-method')
assertEqual(baz:testMixinMethod(), 'mixin-method')

assertNil(foo.testMixinGetter)
assertNil(bar.testMixinGetter)
assertNil(baz.testMixinGetter)

foo.testMixinSetter = 'mixin-property'
bar.testMixinSetter = 'mixin-property'
baz.testMixinSetter = 'mixin-property'

assertEqual(foo.testMixinGetter, 'mixin-property')
assertEqual(bar.testMixinGetter, 'mixin-property')
assertEqual(baz.testMixinGetter, 'mixin-property')

assertError(function() class('Foo') end, 'class already defined')

assertError(function() foo.undefined = 'test' end, 'leading underscore required')
assertError(function() bar.undefined = 'test' end, 'leading underscore required')
assertError(function() baz.undefined = 'test' end, 'leading underscore required')

assertError(function() return foo.undefined end, 'undefined class member')
assertError(function() return bar.undefined end, 'undefined class member')
assertError(function() return baz.undefined end, 'undefined class member')

assertError(function() foo.getFoo = 'test' end, 'cannot override class member')
assertError(function() bar.getFoo = 'test' end, 'cannot override class member')
assertError(function() bar.getBar = 'test' end, 'cannot override class member')
assertError(function() baz.getFoo = 'test' end, 'cannot override class member')
assertError(function() baz.getBar = 'test' end, 'cannot override class member')
assertError(function() baz.getBaz = 'test' end, 'cannot override class member')

assertError(function() foo._foo = 'test' end, 'cannot access private class property')
assertError(function() bar._foo = 'test' end, 'cannot access private class property')
assertError(function() bar._bar = 'test' end, 'cannot access private class property')
assertError(function() baz._foo = 'test' end, 'cannot access private class property')
assertError(function() baz._bar = 'test' end, 'cannot access private class property')
assertError(function() baz._baz = 'test' end, 'cannot access private class property')

assertError(function() foo:testFoo() end, 'cannot declare class property outside of __init')
assertError(function() bar:testFoo() end, 'cannot declare class property outside of __init')
assertError(function() bar:testBar() end, 'cannot declare class property outside of __init')
assertError(function() baz:testFoo() end, 'cannot declare class property outside of __init')
assertError(function() baz:testBar() end, 'cannot declare class property outside of __init')
assertError(function() baz:testBaz() end, 'cannot declare class property outside of __init')
