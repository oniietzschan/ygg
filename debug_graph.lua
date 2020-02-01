local Graph = {}
local GraphMT = {
  __index = Graph,
}

function Graph:_new(runner)
  self._runner = runner
  self._tree = {}
  self:_expand(self._tree, self._runner._action)
  return self
end

function Graph:_expand(branch, action)
  local descendants = 0
  branch.action = action
  branch.len = 0

  if action.class == 'ACTION' then
    branch.name = action.name
    branch.descendants = 0

  else
    if action.class == 'SELECTOR' then
      branch.name = 'Sel: ' .. action.name
    elseif action.class == 'SEQUENCE' then
      branch.name = 'Seq: ' .. action.name
    end
    branch.len = #action._actions
    for i = 1, branch.len do
      branch[i] = {}
      descendants = descendants + self:_expand(branch[i], action._actions[i])
    end
    branch.descendants = descendants
  end

  return descendants + 1
end

local lg = love.graphics

local PAD_H = 2
local PAD_V = 1
local INDENT = 15
local COLOR_NODE_INACTIVE = {0.9, 0.9, 0.9, 0.75}
local COLOR_NODE_ACTIVE   = {1.0, 1.0, 1.0, 1}
local COLOR_TEXT = {0, 0, 0, 1}

function Graph:draw(x, y)
  lg.push('all')
  self:_drawNode(self._tree, x, y)
  lg.pop()
end

function Graph:_drawNode(branch, x, y)
  local font = lg.getFont()
  local w = font:getWidth(branch.name) + (PAD_H * 2)
  local h = font:getHeight()           + (PAD_V * 2)

  -- Draw current node.
  lg.setColor(self:_isActionActive(branch.action) and COLOR_NODE_ACTIVE or COLOR_NODE_INACTIVE)
  lg.rectangle('fill', x, y, w, h)
  lg.setColor(COLOR_TEXT)
  lg.print(branch.name, x + PAD_H, y + PAD_V)

  -- Draw leaves.
  x = x + INDENT
  for i = 1, branch.len do
    local prevDescendants = 1
    if i >= 2 then
      prevDescendants = branch[i - 1].descendants + 1
    end
    y = y + (prevDescendants * (h + PAD_V))
    self:_drawNode(branch[i], x, y)
  end
end

function Graph:_isActionActive(action)
  local runner = self._runner
  while true do
    if runner._action == action then
      return true

    elseif runner._next == nil then
      local actions = runner._action._actions
      return actions[runner.index] == action
    end

    runner = runner._next
  end
end

return function(...)
  return setmetatable({}, GraphMT)
    :_new(...)
end
