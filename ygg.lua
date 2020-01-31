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

local NO_INDEX = -1
local NO_NODE = {}

do
  local Action = {}
  local ActionMT = {__index = Action}

  setmetatable(Ygg, {
    __call = function(_, ...)
      return setmetatable({}, ActionMT)
        :new(...)
    end,
  })

  function Action:new(name, fn)
    if type(name) == 'function' then
      name, fn = '<Action>', name
    end
    assertType(fn, 'function', 'action function')
    self.name = name
    self._fn = fn
    return self
  end

  function Action:update(_, entity, dt)
    return self._fn(entity, dt)
  end
end

do
  local function _new(self, name)
    self.name = name
    self._actions = {}
    self._len = 0
    return self
  end

  local function _add(self, action)
    self._len = self._len + 1
    self._actions[self._len] = action
    return self
  end

  do
    local Selector = {
      new = _new,
      add = _add,
    }
    local SelectorMT = {__index = Selector}

    function Ygg.selector(...)
      return setmetatable({}, SelectorMT)
        :new(...)
    end

    function Selector:update(index, ...)
      for i = index, self._len do
        local node = self._actions[i]
        if node._fn == nil then
          -- Node is a metanode, push onto stack.
          return nil, node, NO_INDEX
        end
        -- print('Running: ' .. node.name)
        local result = node:update(index, ...)
        if result == true then
          return true, NO_NODE, NO_INDEX
          -- return true
        elseif result == nil then
          return nil, NO_NODE, i
        end
      end
      return false, NO_NODE, NO_INDEX -- All sub-nodes failed.
    end
  end

  do
    local Sequence = {
      new = _new,
      add = _add,
    }
    local SequenceMT = {__index = Sequence}

    function Ygg.sequence(...)
      return setmetatable({}, SequenceMT)
        :new(...)
    end

    function Sequence:update(index, ...)
      for i = index, self._len do
        local node = self._actions[i]
        -- print('Running: ' .. node.name)
        local result = node:update(index, ...)
        if result == false then
          return false, NO_NODE, NO_INDEX
        elseif result == nil then
          return nil, NO_NODE, i
        end
      end
      return true, NO_NODE, NO_INDEX -- All sub-nodes succeeded.
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

  function Runner:new(action)
    assertType(action, 'table', 'action')
    self._action = action
    self._index = 1
    self.finished = false
    return self
  end

  function Runner:update(...)
    if self._next then
      self._next:update(...)
      if self._next.finished then
        self._next = nil
        self._index = self._index + 1
      else
        return
      end
    end

    -- print('Running: ' .. tostring(self._action.name))
    local status, node, index = self._action:update(self._index, ...)
    if status ~= nil then
      self.finished = true
      self._index = 1
    elseif index ~= NO_INDEX then
      self._index = index
    elseif node ~= NO_NODE then
      self._next = Ygg.run(node)
      self:update(...)
    end
  end
end

return Ygg
