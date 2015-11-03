
function enum(names)
  local rv = {}
  for i, name in ipairs(names) do
    rv[name] = i
  end
  return rv
end

function difference(num1, num2)
  if num1 > num2 then
   return num1 - num2
 else
   return num2 - num1
 end
end

function concat(t1,t2)
  for i = 1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

function comparePosition(pos1, pos2)
  return (pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z)
end

function copy(original)
  local success, data = serpent.load(serpent.dump(original))
  if not success then
    error('Error copying data')
  end
  return data
end

RandomWalk = class('RandomWalk')

function RandomWalk:initialize(startingPos)
  if startingPos then
    self.position = startingPos
  else
    self.position = {x=0, y=0}
  end
  self.visited = {}
  self.visited[self.position.x .. self.position.y] = true
end

function RandomWalk:next()
  local pos = {x=self.position.x, y=self.position.y}
  local moves = {
    {'x', 1}, {'x', -1},
    {'y', 1}, {'y', -1},
  }
  for i=1,4 do
    local move = table.remove(moves, math.random(1, #moves))
    pos[move[1]] = self.position[move[1]] + move[2]
    if not self.visited[pos.x .. pos.y] then
      self.visited[pos.x .. pos.y] = true
      self.position = pos
      return pos
    end
  end
  return false
end

function isTurtle(item)
  return item and (item.name == 'ComputerCraft:CC-Turtle' or
                   item.name == 'ComputerCraft:CC-TurtleExpanded' or
                   item.name == 'ComputerCraft:CC-TurtleAdvanced')
end
