require 'busted'

local Ygg = require 'ygg'

-- Sequence: Executes it's children sequentially until one succeeds.
-- Selector: "Tries" to execute its children in order until one succeeds.
-- Action: Can be run, fail, or succeed.

describe('Ygg:', function()
  it('Basic functionality', function()
    local isHungry = Ygg(function(this)
      print('RUNNING: isHungry')
      return this.hunger >= 50
    end)
    local isSleepy = Ygg(function(this)
      print('RUNNING: isSleepy')
      return this.tiredness >= 100
    end)
    local eat = Ygg(function(this, dt)
      print('RUNNING: eat')
      if this.hunger == 0 then
        return false
      end
      this.state = 'eating'
      this.hunger = math.max(0, this.hunger - 25 * dt)
      return (this.hunger == 0) and true or nil
    end)
    local sleep = Ygg(function(this, dt)
      print('RUNNING: sleep')
      if this.tiredness == 0 then
        return false
      end
      this.state = 'sleeping'
      this.tiredness = math.max(0, this.tiredness - 10 * dt)
      return (this.tiredness == 0) and true or nil
    end)
    local idle = Ygg(function(this, dt)
      print('RUNNING: idle')
      this.state = 'idle'
      this.hunger = this.hunger + 10 * dt
      this.tiredness = this.tiredness + 10 * dt
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

    local entity = {
      state = 'idle',
      hunger = 30,
      tiredness = 70,
    }

    local runner = Ygg.run(tree, entity)

    local expectedResults = {
      {state =     'idle', hunger = 40, tiredness =  80},
      {state =     'idle', hunger = 50, tiredness =  90},
      {state =   'eating', hunger = 25, tiredness =  90},
      {state =   'eating', hunger =  0, tiredness =  90},
      {state =     'idle', hunger = 10, tiredness = 100},
      {state = 'sleeping', hunger = 10, tiredness =  90},
      {state = 'sleeping', hunger = 10, tiredness =  80},
      {state = 'sleeping', hunger = 10, tiredness =  70},
      {state = 'sleeping', hunger = 10, tiredness =  60},
      {state = 'sleeping', hunger = 10, tiredness =  50},
    }
    for _, expected in ipairs(expectedResults) do
      runner:update(1)
      print(("Hunger: %d, Tired: %d\n"):format(entity.hunger, entity.tiredness))
      assert.same(expected, entity)
    end
  end)
end)
