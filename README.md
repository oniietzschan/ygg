Ygg
===

[![Build Status](https://travis-ci.org/oniietzschan/ygg.svg?branch=master)](https://travis-ci.org/oniietzschan/ygg)
[![Codecov](https://codecov.io/gh/oniietzschan/ygg/branch/master/graph/badge.svg)](https://codecov.io/gh/oniietzschan/ygg)
![Lua](https://img.shields.io/badge/Lua-JIT%2C%205.1-blue.svg)
![Might Makes Right](https://img.shields.io/badge/license-Might%20Makes%20Right-red)

Behaviour trees in Lua.

![A High Resolution Photo Of A 53-Year-Old Man Manipulating His Sphincter](https://i.ibb.co/kQCdwm0/2020-02-01-behaviour-tree.gif)

```lua
local isHungry = Ygg(function(this)
  return this.hunger >= 50
end)

local isSleepy = Ygg(function(this)
  return this.tiredness >= 100
end)

local eat = Ygg(function(this, dt)
  if this.hunger == 0 then
    return false
  end
  this.hunger = math.max(0, this.hunger - 10 * dt)
  return (this.hunger == 0) and true or nil
end)

local sleep = Ygg(function(this, dt)
  if this.tiredness == 0 then
    return false
  end
  this.tiredness = math.max(0, this.tiredness - 5 * dt)
  return (this.tiredness == 0) and true or nil
end)

local idle = Ygg(function(this, dt)
  this.hunger = this.hunger + dt
  this.tiredness = this.tiredness + dt
  return true
end)

local tree = Ygg.selector()
  :add(
    Ygg.sequence()
      :add(isHungry)
      :add(eat)
  )
  :add(
    Ygg.sequence()
      :add(isSleepy)
      :add(sleep)
  )
  :add(idle)

local runner = Ygg.run(tree)

local entity = {
  hunger = 25,
  tiredness = 0,
}

for _ = 1, 10 do
  print(("Hunger: %d, Tired: %d"):format(entity.hunger, entity.tiredness))
  local dt = 1
  -- :update() arguments will be passed into action functions.
  runner:update(entity, dt)
end
```

Documentation
-------------

Coming soon???? You're on your own for now, chief.

Debug Graph
-----------

Included in the repository is an optional file `debug_graph.lua` which you can use to help visualize your tree and work out issues. You can use it like so:

```lua

local YggDebugGraph = require 'debug_graph'
local graph = YggDebugGraph(yggTreeRunner)

function love.draw()
  local x, y = 10, 10
  graph:draw(x, y)
end
```
