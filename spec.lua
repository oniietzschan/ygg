require 'busted'

local Ygg = require 'ygg'

-- Sequence: Executes it's children sequentially until one succeeds.
-- Selector: "Tries" to execute its children in order until one succeeds.
-- Action: Can be run, fail, or succeed.

describe('Ygg:', function()
  it('Basic functionality', function()
    local isHungry = Ygg(function(this, dt)
      return this.hunger > 50
    end)
    local isSleepy = Ygg(function(this, dt)
      return this.tiredness > 100
    end)
    local eat = Ygg(function(this, dt)
      -- print('RUNNING: eat')
      if this.hunger == 0 then
        return false
      end
      this.hunger = math.max(0, this.hunger - 10 * dt)
      return (this.hunger == 0) and true or nil
    end)
    local sleep = Ygg(function(this, dt)
      -- print('RUNNING: sleep')
      if this.tiredness == 0 then
        return false
      end
      this.tiredness = math.max(0, this.tiredness - 5 * dt)
      return (this.tiredness == 0) and true or nil
    end)
    local idle = Ygg(function(this, dt)
      -- print('RUNNING: idle')
      this.hunger = this.hunger + dt
      this.tiredness = this.tiredness + dt
      return true
    end)

    local tree = Ygg.selector()
      -- :add(
      --   Ygg.sequence()
      --     :add(isHungry)
      --     :add(eat)
      -- )
      -- :add(
      --   Ygg.sequence()
      --     :add(isSleepy)
      --     :add(sleep)
      -- )
      :add(eat)
      :add(sleep)
      :add(idle)

    local entity = {
      hunger = 25,
      tiredness = 0,
    }

    local runner = Ygg.run(tree, entity)

    for _ = 1, 10 do
      print(("Hunger: %d, Tired: %d"):format(entity.hunger, entity.tiredness))
      runner:update(1)
    end
  end)
end)
