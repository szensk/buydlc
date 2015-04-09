--

local function animation(image, width, height, time, spacingx, spacingy)
  --member variables
  local ct = 0
  local spacingy = spacingy or 0
  local spacingx = spacingx or 0
  local cframe = 1
  local a = {} -- self
  --initialize
  local x,y = 0,0
  local imgw,imgh = image:getWidth(), image:getHeight()
  local quads = {} -- create quads
  while y < imgh and not done do
    quads[#quads + 1] = love.graphics.newQuad(x, y, width, height, imgw, imgh)
    x = x + width + spacingx
    if x >= imgw then
      x = 0
      y = y + height + spacingy
    end
  end
  local frames = #quads
  local frame_time = time / frames

  --methods
  a.update = function(dt)
    ct = ct + dt
    if ct > frame_time then 
      ct = 0
      cframe = cframe + 1
      if cframe > frames then
        cframe = 1
      end
    end
  end

  a.draw = function(...)
    love.graphics.draw(image, quads[cframe], ...)
  end

  return a
end

-- animation("mario.png", 16, 32, 3)

return animation
