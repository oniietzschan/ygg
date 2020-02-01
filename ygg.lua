--[[

Ygg v0.0.0
===============

Behaviour trees by shru.

https://github.com/oniietzschan/ygg

LICENSE
-------

Whoever knows how to take, to defend, the thing — to him belongs property.

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
    self.func = fn
    return self
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

  local function _update(self, runner, ...)
    while runner.index <= self._len do
      local node = self._actions[runner.index]
      if node.class ~= CLASS.ACTION then
        return nil, node -- Node is a metanode, push onto stack.
      end
      -- print('Running: ' .. node.name)
      local result = node.func(...)
      if result == self._exitOnResult then
        return result, NO_NODE
      elseif result == nil then
        return nil, NO_NODE
      end
      runner.index = runner.index + 1
    end
    return self._statusIfFinished, NO_NODE
  end

  do
    local Selector = {
      class = CLASS.SELECTOR,
      new = _new,
      add = _add,
      update = _update,
      _exitOnResult = true,
      _statusIfFinished = false,
    }
    local SelectorMT = {__index = Selector}

    function Ygg.selector(...)
      return setmetatable({}, SelectorMT)
        :new(...)
    end
  end

  do
    local Sequence = {
      class = CLASS.SEQUENCE,
      new = _new,
      add = _add,
      update = _update,
      _exitOnResult = false,
      _statusIfFinished = true,
    }
    local SequenceMT = {__index = Sequence}

    function Ygg.sequence(...)
      return setmetatable({}, SequenceMT)
        :new(...)
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
    self.index = 1
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
        self.index = 1
        return
      else
        self.index = self.index + 1
      end
    end

    -- print('Running: ' .. tostring(self._action.name))
    local status, node = self._action:update(self, ...)
    if status ~= nil then
      self.status = status
      self.index = 1
    elseif node ~= NO_NODE then
      self._next = Ygg.run(node)
      self:update(...)
    end
  end
end

return Ygg
