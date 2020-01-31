require 'busted'

local Ygg = require 'ygg'

-- Sequence: Executes it's children sequentially until one succeeds.
-- Selector: "Tries" to execute its children in order until one succeeds.
-- Action: Can be run, fail, or succeed.

describe('Ygg:', function()
  it('Basic functionality', function()
    local isHungry = Ygg('isHungry', function(this)
      return this.hunger >= 50
    end)
    local isSleepy = Ygg('isSleepy', function(this)
      return this.tiredness >= 100
    end)
    local eat = Ygg('eat', function(this)
      if this.hunger == 0 then
        return false
      end
      this.state = 'eating'
      this.hunger = math.max(0, this.hunger - 25)
      return (this.hunger == 0) and true or nil
    end)
    local sleep = Ygg('sleep', function(this)
      if this.tiredness == 0 then
        return true
      end
      this.state = 'sleeping'
      this.tiredness = math.max(0, this.tiredness - 30)
      return nil
    end)
    local idle = Ygg('idle', function(this)
      this.state = 'idle'
      this.hunger = this.hunger + 10
      this.tiredness = this.tiredness + 10
      return true
    end)

    local tree = Ygg.selector('root')
      :add(
        Ygg.sequence('hunger sequence')
          :add(isHungry)
          :add(eat)
      )
      :add(
        Ygg.sequence('sleep sequence')
          :add(isSleepy)
          :add(sleep)
      )
      :add(idle)

    local runner = Ygg.run(tree)
    local entity = {
      state = 'idle',
      hunger = 30,
      tiredness = 70,
    }

    local expectedResults = {
      {state =     'idle', hunger = 40, tiredness =  80},
      {state =     'idle', hunger = 50, tiredness =  90},
      {state =   'eating', hunger = 25, tiredness =  90},
      {state =     'idle', hunger = 10, tiredness = 100},
      {state = 'sleeping', hunger = 10, tiredness =  70},
      {state = 'sleeping', hunger = 10, tiredness =  40},
      {state = 'sleeping', hunger = 10, tiredness =  10},
      {state = 'sleeping', hunger = 10, tiredness =   0},
      {state =     'idle', hunger = 20, tiredness =  10},
    }
    for _, expected in ipairs(expectedResults) do
      runner:update(entity)
      -- print(("State: %8s, Hunger: %3d, Tired: %3d"):format(entity.state, entity.hunger, entity.tiredness))
      assert.same(expected, entity)
    end
  end)

  it('Should be able to have a Action in Selector return nil (although this is unusual, maybe?)', function()
    local tryEat = Ygg('tryEat', function(this)
      this.state = 'eating'
      if this.hunger == 0 then
        return false
      end
      this.hunger = math.max(0, this.hunger - 25)
      return nil
    end)
    local idle = Ygg('idle', function(this)
      this.state = 'idle'
      return true
    end)

    local tree = Ygg.selector('root')
      :add(tryEat)
      :add(idle)

    local runner = Ygg.run(tree)
    local entity = {
      state = 'idle',
      hunger = 60,
    }

    local expectedResults = {
      {state = 'eating', hunger = 35},
      {state = 'eating', hunger = 10},
      {state = 'eating', hunger =  0},
      {state =   'idle', hunger =  0},
    }
    for _, expected in ipairs(expectedResults) do
      runner:update(entity)
      -- print(("State: %6s, Hunger: %2d"):format(entity.state, entity.hunger))
      assert.same(expected, entity)
    end
  end)

  it('Should reset to first index if Selector within Sequence fails', function()
    local addIdol = Ygg('addIdol', function(this)
      this.idols = this.idols + 1
      return true
    end)
    local willFail = Ygg('willFail', function()
      return false
    end)

    local tree = Ygg.sequence('root')
      :add(addIdol)
      :add(
        Ygg.selector('fail selector')
          :add(willFail)
          :add(willFail)
          :add(willFail)
      )

    local runner = Ygg.run(tree)
    local entity = {
      idols = 0,
    }

    local expectedResults = {
      {idols = 1},
      {idols = 2},
      {idols = 3},
    }
    for _, expected in ipairs(expectedResults) do
      runner:update(entity)
      -- print(("Idols: %d"):format(entity.idols))
      assert.same(expected, entity)
    end
  end)

  it('Should be able to create actions without a name', function()
    local action = Ygg(function() end)
    assert.same('<Action>', action.name)
  end)

  it('Invalid scripts should relay error message', function()
    local expectedError = "action function must be a function, got: nil"
    assert.has_error(function() Ygg(11) end, expectedError)
  end)
end)
