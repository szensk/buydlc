-- physics playground
-- i'll work on this until I get platformer physics to work in Box2D.

-- libraries
local sti    = require 'sti'
local push   = require 'inpush'
local anim   = require 'anim8.anim8'
local action = push.action

-- actual stuff
local map 
local world
local collision
local showCollide = false
local mario = love.graphics.newImage("assets/marios.png")
local grid  = anim.newGrid(40, 34, mario:getWidth(), mario:getHeight())
local player = {
  sx = 3 * 16,
  sy = 28 * 16,
  w = 16,
  h = 32,
  floating = true,
  shrooms = 0,
  anim = anim.newAnimation(grid('1-8', 1), 0.1)
}
local mushroom = love.graphics.newImage("assets/blueshroom.png")
local CATEGORIES = {
  PLAYER = 1,
  STATIC = 2,
  ITEMS  = 3
}
local items = {}

local function beginContact(a, b, collision)
  if b:getUserData() == player then
    player.floating = false
    local nx, ny = collision:getNormal()
    -- print(nx, ny)
    -- when you jump and hit a block
    -- unfortunately need to handle when the collision 
    if nx == -1 and ny == 0 then player.floating = true end
  end
  local item = b:getUserData()
  local actor = a:getUserData()
  if item and item.typ == "pickup" and actor == player then
    player.shrooms = player.shrooms + 1
    item.fixture:destroy()
    item.body:destroy()
    table.remove(items, item.id) --maybe a double linked list instead?
  end
end

local function endContact(a, b, collision)
  if b:getUserData() == player then
    player.floating = true
  end
end

local function create_world(args)
  local meter = args.meter or 16
  local gravity = args.gravity or 9.81 * meter
  love.physics.setMeter(meter)
  local world = love.physics.newWorld(0,0)
  world:setGravity(0, gravity)
  world:setCallbacks(beginContact, endContact)
  return world
end

local function create_terrain(map)
  local terrain = map:box2d_init(world)
    for i,c in ipairs(map.box2d_collision) do
      --c.fixture:setFriction(5)
      c.fixture:setCategory(CATEGORIES.STATIC)
    end
  return terrain
end

local function set_controls()
  push.bind('a', function() player.body:applyForce(-400, 0) end)
  push.bind('d', function() player.body:applyForce(400, 0) end)
  push.bind('w', function() -- jump
    if not player.floating then 
      player.body:applyForce(0, -6000) 
    end 
  end)
  push.bind('s', function() end) --drop down
  push.bind('q', action.toggleCollision)
  push.bind('escape', function() love.event.quit() end)
end

local function new_item(x,y,idx)
  local i = { name = "mushroom", typ = "pickup", id = idx + 1 }
    i.body  = love.physics.newBody(world, x, y, "dynamic")
    i.body:setFixedRotation(true)
    i.body:setMass(0.001)
    i.shape = love.physics.newRectangleShape(16, 16)
    i.fixture = love.physics.newFixture(i.body, i.shape, 1)
    i.fixture:setRestitution(0.4)
    i.fixture:setCategory(CATEGORIES.ITEMS)
    i.fixture:setMask(CATEGORIES.ITEMS)
    i.fixture:setUserData(i)
  return i
end

function love.load()
  love.graphics.setBackgroundColor(255,255,255)
  -- map
  map = sti.new("assets/tube.lua", {"box2d"})
  -- physiks
  world = create_world{meter = 16}
  collision = create_terrain(map)
  -- create player collision
  player.body = love.physics.newBody(world, player.sx, player.sy, "dynamic")
  --player.body:setUserData(player)
  player.body:setMass(1000)
  player.body:setFixedRotation(true)
  player.shape   = love.physics.newRectangleShape(player.w - 2, player.h - 2)
  player.fixture = love.physics.newFixture(player.body, player.shape, 1)
  player.fixture:setCategory(CATEGORIES.PLAYER)
  player.fixture:setUserData(player)
  -- input
  set_controls()
end

function love.draw()
  -- store color
  local r,g,b,a = love.graphics.getColor()
  -- setup camera
  local tx = love.graphics.getWidth()/2 - (player.body:getX() + player.w/2)
  local ty = love.graphics.getHeight()/2 - (player.body:getY() + player.h/2)
  tx, ty = math.floor(tx), math.floor(ty) --removes jitter from subpixel alignment
  love.graphics.translate(tx, ty)
  -- draw map
  map:draw()
  -- draw items
  for i,v in ipairs(items) do
    love.graphics.draw(mushroom, v.body:getX()-8, v.body:getY()-8)
    v.id = i
  end

  -- debug player
  local px, py = math.floor(player.body:getX()), math.floor(player.body:getY())
  player.anim:draw(mario, px - 28, py - 16)

  -- debug collision 
  if showCollide then 
    love.graphics.setColor(0, 162, 232)
    love.graphics.print( ("x: %0.0f y: %0.0f"):format(px, py), -tx, -ty)
    --collision box
    love.graphics.print("floating: " .. tostring(player.floating), px-32, py-32)
    -- smooth out point jitter
    local pts = {player.body:getWorldPoints(player.shape:getPoints())}
    for i,v in ipairs(pts) do pts[i] = math.floor(v) end
    -- draw points
    love.graphics.polygon("line", pts)
    love.graphics.setColor(255, 21, 0)
    map:box2d_draw()
  end
  -- restore color
  love.graphics.setColor(r,g,b,a)
end

function love.update(dt)
  player.anim:update(dt)
  map:update(dt)
  world:update(dt)

  push.update(dt)

  love.window.setTitle("gravity: " .. tostring(love.timer.getFPS()))
  if action.toggleCollision.pressed then
    showCollide = not showCollide
  end
end

function love.mousepressed(x,y, mb)
  if mb == 'l' then
    local tx = love.graphics.getWidth()/2 - (player.body:getX() + player.w/2)
    local ty = love.graphics.getHeight()/2 - (player.body:getY() + player.h/2)
    items[#items + 1] = new_item(x-tx,y-ty, #items)
  end
end

function love.keypressed(key, rep)
  push.keypressed(key)
end
