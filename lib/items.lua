require('class')
Item = class('Item')
Materials = class('Materials')
Recipe = class('Recipe')
Recipes = {}

local recipes = {
  planks = { -- 4
    "log"
  },
  stick = { -- 2
    "planks", nil, nil,
    "planks"
  },
  chest = {
    "planks", "planks", "planks",
    "planks", nil     , "planks",
    "planks", "planks", "planks"
  },
  furnace = {
    "cobblestone", "cobblestone", "cobblestone",
    "cobblestone", nil          , "cobblestone",
    "cobblestone", "cobblestone", "cobblestone"
  },
  torch = { -- 4
    "coal", nil, nil,
    "stick"
  },
  glassPane = { -- 16
    "glass", "glass", "glass",
    "glass", "glass", "glass"
  },
  paper = { -- 3
    "reeds", "reeds", "reeds"
  },
  floppyDisk = {
    "redstone", nil, nil,
    "paper"
  },
  diskDrive = {
    "stone", "stone"   , "stone",
    "stone", "redstone", "stone",
    "stone", "redstone", "stone"
  },
  computer = {
    "stone", "stone"     , "stone",
    "stone", "redstone"  , "stone",
    "stone", "glass_pane", "stone"
  },
  turtle = {
    "iron_ingot", "iron_ingot", "iron_ingot",
    "iron_ingot", "ComputerCraft:CC-Computer"  , "iron_ingot",
    "iron_ingot", "chest"     , "iron_ingot"
  },
  diamondPick = {
    "diamond", "diamond", "diamond",
    nil      , "stick"  , nil,
    nil      , "stick"
  },
  craftingTable = {
    "planks", "planks", nil,
    "planks", "planks"
  },
  bucket = {
    'iron_ingot', nil, 'iron_ingot',
    nil, 'iron_ingot'
  },
}

local nameMap = {
  ['minecraft:cobblestone'] = 'Cobblestone',
  ['minecraft:diamond_pickaxe'] = 'Diamond Pick',
  ['minecraft:crafting_table'] = 'Crafting Table',
  ['minecraft:coal'] = 'Coal',
  ['minecraft:dirt'] = 'Dirt',
  ['minecraft:log'] = 'Wood',
  ['minecraft:sapling'] = 'Saplings',
  ['minecraft:reeds'] = 'Sugar Cane',
  ['minecraft:water_bucket'] = 'Water Bucket',
}

function Item:initialize(name, count, metadata, slot)
  self.name = name
  self.count = count
  self.metadata = metadata
  self.slot = slot
end

function Item:__tostring()
  local rv = "Item: " .. self.name .. " count=" .. self.count
  if self.metadata ~= nil then
    rv = rv .. " meta=" .. self.metadata
  end
  if self.slot ~= nil then
    rv = rv .. " slot=" .. self.slot
  end
  return rv
end

function Item:displayName()
  local name = nameMap[self.name]
  if name then
    return name
  else
    return self.name
  end
end

function Item.static.normalizeName(name)
  if string.find(name, ':') == nil then
    return 'minecraft:' .. name
  end
  return name
end

function Item.static.fromString(string, count)
  if count == nil then count = 1 end
  return Item:new(Item.normalizeName(string), count)
end

function Item.static.fromTable(data)
  if data[1] and data[2] then
    return Item.fromString(data[1], data[2])
  end
  local name = data['name']
  local metadata, count
  if data['count'] then
    count = data['count']
  else
    count = 1
  end
  if data['metadata'] then
    metadata = data['metadata']
  elseif data['damage'] then
    metadata = data['damage']
  end
  return Item:new(name, count, metadata)
end

function Item.static.resolve(item)
  if class.Object.isInstanceOf(item, Item) then
    return item
  elseif type(item) == 'table' then
    return Item.fromTable(item)
  elseif type(item) == 'string' then
    return Item.fromString(item)
  end
  return nil
end

function Materials:initialize(data)
  self.data = data
end

function Materials:addItem(item, count)
  item = Item.resolve(item)
  if count == nil then
    count = item.count
  end
  if self.data[item.name] then
    self.data[item.name] = self.data[item.name] + count
  else
    self.data[item.name] = count
  end
end

function Materials:removeItem(item, count)
  item = Item.resolve(item)
  if count == nil then
    count = item.count
  end
  if self.data[item.name] then
    self.data[item.name] = self.data[item.name] - count
    if self.data[item.name] <= 0 then
      self.data[item.name] = nil
    end
  end
end

function Materials:getItems()
  local rv = {}
  for name,count in pairs(self.data) do
    table.insert(rv, Item.fromString(name, count))
  end
  return rv
end

function Materials:numMaterials()
  local count = 0
  for _,_ in pairs(self.data) do
    count = count + 1
  end
  return count
end

function Materials:count(item)
  local item = Item.resolve(item)
  if item and self.data[item.name] then
    return self.data[item.name]
  end
  return 0
end

function Materials:__serialize()
  return self.data
end

function Materials.static.fromFile(filename)
  local file = fs.open(filename, 'r')
  local success, data = serpent.load(file.readAll())
  if success then
    return Materials:new(data)
  else
    error('Corrupted materials data.')
  end
end

function Materials.static.fromTable(data)
  local rv = Materials:new({})
  for _,value in pairs(data) do
    if class.Object.isInstanceOf(value, Item) then
      rv:addItem(value)
    elseif type(value) == 'table' then
      rv:addItem(value[1], value[2])
    elseif type(value) == 'string' then
      rv:addItem(value, 1)
    else
      error('Invalid data.')
    end
  end
  return rv
end

function Materials.static.resolve(materials)
  if class.Object.isInstanceOf(materials, Materials) then
    return materials
  elseif type(materials) == 'table' then
    return Materials.fromTable(materials)
  end
  return nil
end

function Recipe:initialize(items)
  self.items = items
end

function Recipe:getMaterials(amount)
  local rv = Materials.fromTable(self.items)
  if amount and amount > 1 then
    for name,count in pairs(rv.data) do
      rv.data[name] = count * amount
    end
  end
  return rv
end

function Recipe.static.fromTable(data)
  local items = {}
  for slotIdx = 1,9 do
    items[slotIdx] = Item.resolve(data[slotIdx])
  end
  return Recipe:new(items)
end

function Recipe.static.resolve(data)
  if class.Object.isInstanceOf(data, Recipe) then
    return data
  elseif type(data) == 'table' then
    return Recipe.fromTable(data)
  end
  return nil
end

for name,recipe in pairs(recipes) do
  Recipes[name] = Recipe.resolve(recipe)
end
