local Container, accessors = class('Container')

accessors.client = function(self) return self.parent.client or self.parent end

function Container:__init(parent)
	self.parent = parent
end

return Container
