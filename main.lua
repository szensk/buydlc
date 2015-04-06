local threads  = {}
local channels = {}
local systems  = {}
local Emitter  = require 'Emitter'
local emitter  = Emitter:new()
local highlighted = nil
local score       = 0
local complete    = 0
local bigfont     = love.graphics.newFont(60)
local normfont    = love.graphics.newFont(16)

-- rectangle stuff
local canvas = love.graphics.newCanvas(2,2)
canvas:renderTo(function() 
  love.graphics.setColor(0, 162, 232)
  love.graphics.rectangle("fill", 0, 0, 2, 2)
end)
local background = love.graphics.newCanvas(2,2)
background:renderTo(function() 
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, 2, 2)
end)
local batch = love.graphics.newSpriteBatch(canvas, 100, "static")
local backbatch = love.graphics.newSpriteBatch(background, 100, "static")

local system = love.graphics.newParticleSystem(canvas, 100)
      system:setParticleLifetime(0.5,1)
      system:setSizeVariation(1)
      system:setSpinVariation(1)
      system:setSpeed(-200, 200)
      system:setAreaSpread("normal", 5, 5)
      system:setParticleLifetime(1)
      system:setLinearAcceleration(-20, -20, 20, 20)
      system:setColors(0, 162, 232, 255, 255, 255, 255, 0)

function love.load()
  --start threads  
  threads.physics = love.thread.newThread("physics.lua")
  threads.physics:start()
  channels.physics = love.thread.getChannel("physicsChannel")

  -- create rectangles
  batch:bind()
  for i=1, 100 do
    local x = love.math.random(0,780)
    local y = love.math.random(0,580)
    local w = love.math.random(10,30)
    local h = love.math.random(10,30)
    local id = batch:add(x, y, 0, w, h)
    backbatch:add(x-2, y-2, 0, w + 2, h + 2)
    complete = complete + (2*w)*(2*h)
    channels.physics:push({x,y,w,h,id})
  end
  batch:unbind()
  love.graphics.setFont(normfont)
end

function love.threaderror(thread, error)
  print("Thread error: " .. error)
end

function love.quit()
  --kill threads
  for k,v in pairs(channels) do 
    v:push("exit")
  end
  for k,v in pairs(threads) do
    v:wait()
  end
end

function love.mousepressed(x, y, button)
  if button == "l" then
    love.thread.getChannel("hit_test"):push({x,y})
  end
end

function love.draw()
  love.graphics.draw(backbatch)
  if highlight then 
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(255, 201, 14)
    love.graphics.rectangle("fill", highlight.x-2, highlight.y-2, highlight.w+4, highlight.h+4)
    love.graphics.setColor(r,g,b,a)
  end
  love.graphics.draw(batch)
  emitter:draw()
  --system:emit(100)
  for i,v in ipairs(systems) do 
    love.graphics.draw(v.sys, v.x, v.y, 0, 2, 2)
  end
  if score >= complete then
    love.graphics.setFont(bigfont)
    local str = "Level completed!\nScore: " .. score
    --local strw = bigfont:getWidth(str)
    love.graphics.print(str, 0, 0)
  end
end

function love.update(dt)
  emitter:update(dt)
  -- update mouse
  love.thread.getChannel("mouse"):push({love.mouse.getX(), love.mouse.getY()})
  -- read for highlight rect
  highlight = love.thread.getChannel("mouseover"):pop()
  -- read for hits
  local p = true
  while p do
    p = love.thread.getChannel("hit"):pop()
    if p then
      score = score + p.w * p.h
      local particle = emitter:addParticle("+" .. p.w * p.h .. " Points", p.x, p.y)
      particle:setColor(love.math.random(0, 255), love.math.random(0, 255), love.math.random(0, 255), 200)
      -- do explosion
      systems[#systems + 1] = {sys = system:clone(), x = p.x + p.w/2, y = p.y + p.h/2} 
      systems[#systems].sys:emit(100)
      --remove rect
      backbatch:set(p.id, 0, 0, 0, 0, 0)
      batch:set(p.id, 0, 0, 0, 0, 0)
    end
  end
  love.window.setTitle("Score: " .. score .. "/" .. complete)
  for i,v in ipairs(systems) do v.sys:update(dt) end
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
end
