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
    self._fn = fn
    return self
  end

  function Action:update(entity, dt)
    return self._fn(entity, dt)
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
      local node = self._actions[i]
      if node._fn == nil then
        -- Node is a metanode, push onto stack.
        return nil, node
      end
      local result = node:update(entity, dt)
      if result == true then
        return true
      elseif result == nil then
        return nil, i
      end
    end
  end
end

do
  local Sequence = {}
  local SequenceMT = {__index = Sequence}

  function Ygg.sequence()
    return setmetatable({}, SequenceMT)
      :new()
  end

  function Sequence:new()
    self._actions = {}
    self._len = 0
    return self
  end

  function Sequence:add(action)
    self._len = self._len + 1
    self._actions[self._len] = action
    return self
  end

  function Sequence:update(index, entity, dt)
    for i = index, self._len do
      local result = self._actions[i]:update(entity, dt)
      if result == false then
        return false
      elseif result == nil then
        return nil, nil, i
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
    self._nodes = {}
    self._len = 0
    self._indexes = {}
    self.entity = entity
    self:_push(action)
    return self
  end

  function Runner:update(dt)
    local status, node, index = self._nodes[self._len]:update(
      self._indexes[self._len],
      self.entity,
      dt
    )
    -- print('update', self._len, '->', status, node, index)
    if status ~= nil then
      if self._len == 1 then
        self._indexes[1] = 1
      else
        self:_pop()
        self:update(dt)
      end

    elseif index then
      self._indexes[self._len] = index

    elseif node then
      self:_push(node)
      self:update(dt)
    end
  end

  function Runner:_push(node)
    self._len = self._len + 1
    self._nodes[self._len] = node
    self._indexes[self._len] = 1
  end

  function Runner:_pop()
    self._nodes[self._len] = nil
    self._indexes[self._len] = nil
    self._len = self._len - 1
    -- increment index of next node.
    self._indexes[self._len] = self._indexes[self._len] + 1
  end
end

return Ygg
