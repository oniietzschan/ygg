--[[

Ygg v0.0.0
===============

Behaviour trees by shru.

https://github.com/oniietzschan/ygg

--]]

local assertType
do
  local ERROR_TEMPLATE = "%s must be a %s, got: %s"

  assertType = function(obj, expectedType, name)
    assert(type(expectedType) == 'string' and type(name) == 'string')
    if type(obj) ~= expectedType then
      error(ERROR_TEMPLATE:format(name, expectedType, tostring(obj)), 2)
    end
  end
end

local Ygg = {}

do
  local Action = {}
  local ActionMT = {__index = Action}

  setmetatable(Ygg, {
    __call = function(_, ...)
      return setmetatable({}, ActionMT)
        :new(...)
    end,
  })

  function Action:new(fn)
    assertType(fn, 'function', 'action function')
    self.update = fn
    return self
  end
end

do
  local Selector = {}
  local SelectorMT = {__index = Selector}

  function Ygg.selector()
    return setmetatable({}, SelectorMT)
      :new()
  end

  function Selector:new()
    self._actions = {}
    self._len = 0
    return self
  end

  function Selector:add(action)
    self._len = self._len + 1
    self._actions[self._len] = action
    return self
  end

  function Selector:update(index, entity, dt)
    for i = index, self._len do
      local result = self._actions[i].update(entity, dt)
      if result == true then
        return true
      elseif result == nil then
        return nil, i
      end
    end
  end
end

do
  local Runner = {}
  local RunnerMT = {__index = Runner}

  function Ygg.run(...)
    return setmetatable({}, RunnerMT)
      :new(...)
  end

  function Runner:new(action, entity)
    assertType(action, 'table', 'action')
    self._nodes = {action}
    self._nodesLen = 1
    self._nodeIndex = 1
    self.entity = entity
    return self
  end

  function Runner:update(dt)
    local status, index = self._nodes[self._nodesLen]:update(self._nodeIndex, self.entity, dt)
    if index then
      self._nodeIndex = index
    end
  end
end

return Ygg
