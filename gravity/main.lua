-- libraries
local sti    = require 'sti'
local push   = require 'inpush'
local action = push.action
push = push.push

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
}

function love.load()
  -- white background
  love.graphics.setBackgroundColor(255,255,255)
  -- map
  map = sti.new("assets/tube")
  -- physiks
  love.physics.setMeter(16)
  world = love.physics.newWorld(0,0) -- a whole new world...
  world:setGravity(0, 9.81*16)
  collision = map:initWorldCollision(world)
  for i,c in ipairs(collision) do
    c.fixture:setFriction(1)
  end
  player.body = love.physics.newBody(world, player.sx, player.sy, "dynamic")
  player.body:setMass(1000)
  player.body:setFixedRotation(true)
  player.shape = love.physics.newRectangleShape(player.w - 2, player.h -2 )
  player.fixture = love.physics.newFixture(player.body, player.shape, 1)
  -- input
  push.bind('a', function() player.body:applyForce(-400, 0) end)
  push.bind('d', function() player.body:applyForce(400, 0)  end)
  push.bind('w', function() player.body:applyForce(0, -1337)  end)
  push.bind('s', function() end)
  push.bind('q', action.toggleCollision)
end

function love.draw()
  local tx = love.graphics.getWidth()/2 - (player.body:getX() + player.w/2)
  local ty = love.graphics.getHeight()/2 - (player.body:getY() + player.h/2)
  love.graphics.translate(tx, ty)
  map:draw()
  local r,g,b,a = love.graphics.getColor()
  -- debug player box, in blue
  love.graphics.setColor(0, 162, 232)
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
  love.window.setTitle("gravity: " .. tostring(love.timer.getFPS()))
  if action.toggleCollision.pressed then
    showCollide = not showCollide
  end
end

function love.keypressed(key, rep)
  if key == "escape" then love.event.quit() end
  push.keypressed(key)
end
