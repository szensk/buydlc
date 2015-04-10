-- physics playground
-- i'll work on this until I get platformer physics to work in Box2D.

-- libraries
local sti    = require 'sti'
local push   = require 'inpush'
local action = push.action

-- actual stuff
local map 
local world
local collision
local showCollide = false
local player = {
  sx = 3 * 16,
  sy = 28 * 16,
  w = 16,
  h = 32,
  floating = true
}
local mushroom = love.graphics.newImage("assets/Mushroom - 1UP.png")
local CATEGORIES = {
  PLAYER = 1,
  STATIC = 2,
  ITEMS  = 3
}
local items = {
  
}

local function beginContact(a, b, collision)
  if b:getUserData() == player then
    player.floating = false
    local nx, ny = collision:getNormal()
    print(nx, ny)
    -- when you jump and hit a block
    -- unfortunately need to handle when the collision 
    if nx == -1 and ny == 0 then player.floating = true end
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
  local terrain = map:initWorldCollision(world)
    for i,c in ipairs(terrain) do
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

local function new_item(x,y)
  local i = {}
    i.body  = love.physics.newBody(world, x, y, "dynamic")
    i.body:setFixedRotation(true)
    i.shape = love.physics.newRectangleShape(16, 16)
    i.fixture = love.physics.newFixture(i.body, i.shape, 1)
    i.fixture:setRestitution(0.4)
    i.fixture:setCategory(CATEGORIES.ITEMS)
    i.fixture:setMask(CATEGORIES.ITEMS)
    i.fixture:setUserData(i)
  return i
end

function love.load()
  -- white background
  love.graphics.setBackgroundColor(255,255,255)
  -- map
  map = sti.new("assets/tube")
  -- physiks
  world = create_world{meter = 16}
  collision = create_terrain(map)
  player.body = love.physics.newBody(world, player.sx, player.sy, "dynamic")
  --player.body:setUserData(player)
  player.body:setMass(1000)
  player.body:setFixedRotation(true)
  player.shape   = love.physics.newRectangleShape(player.w - 2, player.h -2 )
  player.fixture = love.physics.newFixture(player.body, player.shape, 1)
  player.fixture:setCategory(CATEGORIES.PLAYER)
  player.fixture:setUserData(player)
  --input
  set_controls()
end

function love.draw()
  local tx = love.graphics.getWidth()/2 - (player.body:getX() + player.w/2)
  local ty = love.graphics.getHeight()/2 - (player.body:getY() + player.h/2)
  tx, ty = math.floor(tx), math.floor(ty) --removes jitter from subpixel alignment
  love.graphics.translate(tx, ty)
  map:draw()
  for i,v in ipairs(items) do
    love.graphics.draw(mushroom, v.body:getX()-8, v.body:getY()-8)
  end
  local r,g,b,a = love.graphics.getColor()
  -- debug player info, in blue
  love.graphics.setColor(0, 162, 232)
  love.graphics.print( ("x: %0.0f y: %0.0f"):format(player.body:getPosition()), -tx, -ty)
  --collision box
  love.graphics.print("floating: " .. tostring(player.floating), player.body:getX()-32, player.body:getY()-32)
  love.graphics.polygon("line", player.body:getWorldPoints(player.shape:getPoints()))
  -- debug collision map, in red
  if showCollide then 
    love.graphics.setColor(255, 21, 0)
    map:drawWorldCollision(collision)
  end
  love.graphics.setColor(r,g,b,a)
end

function love.update(dt)
  map:update(dt)
  world:update(dt)
  push.update(dt)
  local lvx, lvy = player.body:getLinearVelocity()
  love.window.setTitle("gravity: " .. tostring(love.timer.getFPS()))
  if action.toggleCollision.pressed then
    showCollide = not showCollide
  end
end

function love.mousepressed(x,y, mb)
  if mb == 'l' then
    local tx = love.graphics.getWidth()/2 - (player.body:getX() + player.w/2)
    local ty = love.graphics.getHeight()/2 - (player.body:getY() + player.h/2)
    items[#items + 1] = new_item(x-tx,y-ty)
  end
end

function love.keypressed(key, rep)
  push.keypressed(key)
end
