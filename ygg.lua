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

local CLASS = {
  ACTION = 'ACTION',
  SELECTOR = 'SELECTOR',
  SEQUENCE = 'SEQUENCE',
}
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
    self.class = CLASS.ACTION -- Lawsuit incoming.
    if type(name) == 'function' then
      name, fn = '<Action>', name
    end
    assertType(fn, 'function', 'action function')
    self.name = name
    self._fn = fn
    return self
  end

  function Action:update(_, ...)
    return self._fn(...)
  end
end

do
  local function _new(self, class, name)
    self.class = class
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
        :new(CLASS.SELECTOR, ...)
    end

    function Selector:update(index, ...)
      for i = index, self._len do
        local node = self._actions[i]
        if node.class ~= CLASS.ACTION then
          -- Node is a metanode, push onto stack.
          return nil, node, NO_INDEX
        end
        -- print('Running: ' .. node.name)
        local result = node:update(index, ...)
        if result == true then
          return true, NO_NODE, NO_INDEX
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
        :new(CLASS.SEQUENCE, ...)
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
    self.status = nil
    return self
  end

  function Runner:update(...)
    if self._next then
      self._next:update(...)
      local status = self._next.status
      if status == nil then
        return
      end
      self._next = nil
      -- This shit kind of sucks, probably refactor eventually.
      if   (self._action.class == CLASS.SEQUENCE and status == false)
        or (self._action.class == CLASS.SELECTOR and status == true)
      then
        self.status = status
        self._index = 1
        return
      else
        self._index = self._index + 1
      end
    end

    -- print('Running: ' .. tostring(self._action.name))
    local status, node, index = self._action:update(self._index, ...)
    if status ~= nil then
      self.status = status
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
