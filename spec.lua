require 'busted'

local Ygg = require 'ygg'

describe('Ygg:', function()
  it('Basic functionality', function()
    local isHungry = Ygg('isHungry', function(this)
      return this.hunger >= 50
    end)
    local isSleepy = Ygg('isSleepy', function(this)
      return this.tiredness >= 100
    end)
    local eat = Ygg('eat', function(this)
      this.state = 'eating'
      this.hunger = math.max(0, this.hunger - 25)
      return (this.hunger == 0) and true or nil
    end)
    local sleep = Ygg('sleep', function(this)
      this.state = 'sleeping'
      this.tiredness = math.max(0, this.tiredness - 30)
      return (this.tiredness == 0) and true or nil
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
      state = '<unset>',
      hunger = 30,
      tiredness = 70,
    }

    local expectedResults = {
      {state =     'idle', hunger = 40, tiredness =  80},
      {state =     'idle', hunger = 50, tiredness =  90},
      {state =   'eating', hunger = 25, tiredness =  90},
      {state =   'eating', hunger =  0, tiredness =  90},
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

  it('Selector should restart if any sub-nodes succeed, including sequence.', function()
    local willAlwaysSucceedOne = Ygg('addIdol', function(this)
      this.expected = this.expected + 1
      return true
    end)
    local willAlwaysSucceedTen = Ygg('addIdol', function(this)
      this.expected = this.expected + 10
      return true
    end)
    local shouldNotBeExecuted = Ygg('willFail', function(this)
      this.unexpected = this.unexpected + 1
      return true
    end)

    local tree = Ygg.selector('root')
      :add(
        Ygg.sequence('success seq')
          :add(willAlwaysSucceedOne)
          :add(willAlwaysSucceedTen)
      )
      :add(shouldNotBeExecuted)

    local runner = Ygg.run(tree)
    local entity = {
      expected = 0,
      unexpected = 0,
    }

    local expectedResults = {
      {expected = 11, unexpected = 0},
      {expected = 22, unexpected = 0},
    }
    for _, expected in ipairs(expectedResults) do
      runner:update(entity)
      assert.same(expected, entity)
    end

    shouldNotBeExecuted:update(nil, {unexpected = -1}) -- Test coverage lololol
  end)

  it('Should reset to first index after Selector succeeds', function()
    local hasPlate = Ygg('hasPlate', function(this)
      return this.plates >= 1
    end)
    local getFood = Ygg('getFood', function(this)
      this.food = this.food + 1
      return true
    end)
    local getPlate = Ygg('getPlate', function(this)
      this.plates = this.plates + 1
      return true
    end)

    local tree = Ygg.selector('root')
      :add(
        Ygg.sequence('food seq')
          :add(hasPlate)
          :add(getFood)
      )
      :add(
        Ygg.sequence('plate seq')
          :add(getPlate)
      )

    local runner = Ygg.run(tree)
    local entity = {
      food = 0,
      plates = 0,
    }

    local expectedResults = {
      {food = 0, plates = 1},
      {food = 1, plates = 1},
      {food = 2, plates = 1},
      {food = 3, plates = 1},
    }
    for _, expected in ipairs(expectedResults) do
      runner:update(entity)
      -- print(("Food: %d, Plates: %d"):format(entity.food, entity.plates))
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
