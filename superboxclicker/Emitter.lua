

local Emitter = {}
Emitter.__index = Emitter

function Emitter:new(x, y)
  local self = {}
  self.x = x or 0
  self.y = y or 0
  self.particles = {}
  --self.delay = .5
  self.lifetime = 0.6
  setmetatable(self, Emitter)
  return self
end

function Emitter:addParticle(text, x, y)
  local p = {}
  p.text = text
  p.x = x
  p.y = y
  p.red = 255
  p.green = 255
  p.blue = 255
  p.alpha = 255
  p.time = 0
  p.yVelocity = 50
  p.lifetime = self.lifetime
  p.fadeSpeed = 500
  p.destroyed = false
  
  p.destroy = function(self)
    self.destroyed = true
  end
  
  p.move = function(self, dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
  end
  
  p.setColor = function(self, r, g, b, a)
    self.red = r or self.red
    self.green = g or self.green
    self.blue = b or self.blue
    self.alpha = a or self.alpha
  end
  
  p.update = function(self, dt)
    self:move(0, -self.yVelocity*dt)
    self.time = self.time + dt
    if self.time > self.lifetime then
      self.alpha = self.alpha - self.fadeSpeed * dt
      if self.alpha <= 1 then
        self.alpha = 0
        self:destroy()
      end
    end
  end
  
  p.draw = function(self)
    love.graphics.setColor(self.red, self.green, self.blue, self.alpha)
    love.graphics.print(self.text, self.x, self.y)
    love.graphics.setColor(255, 255, 255, 255)
  end

  self.particles[#self.particles + 1] = p
  return p
end


function Emitter:update(dt)
  for k, particle in ipairs(self.particles) do
    if not particle.destroyed then 
      particle:update(dt)
    else 
      table.remove(self.particles, k) 
    end
  end
end


function Emitter:draw()
  for k, particle in ipairs(self.particles) do
    particle:draw()
  end
end

return Emitter
