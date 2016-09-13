local physicsChannel = love.thread.getChannel("physicsChannel")
local rects = {}
local mouse = {}

local i = 1
while i <= 100 do
  local v = physicsChannel:pop()
  if v then
    v[3] = v[3]*2
    v[4] = v[4]*2
    rects[i] = v
    i = i + 1
  end
end

local function find_rect_index(x, y)
  local ind = nil
  for i=1, 100 do
    local r = rects[i]
    if r and x >= r[1] and x <= (r[1] + r[3]) and y >= r[2] and y <= (r[2] + r[4]) then
      return i
    end
  end
  return ind
end

local exit = false
while not exit do 

  local mouse = love.thread.getChannel("mouse"):pop()
  if mouse then
    local rect_hit = find_rect_index(mouse[1], mouse[2])
    if rect_hit then
      love.thread.getChannel("mouseover"):push({
          x = rects[rect_hit][1],
          y = rects[rect_hit][2],
          w = rects[rect_hit][3],
          h = rects[rect_hit][4]
        })
    end
  end
  local p = true
  while p do
    p = love.thread.getChannel("hit_test"):pop()
    if p then 
      local ind = find_rect_index(p[1], p[2])
      if ind then
        love.thread.getChannel("hit"):push({
          x = rects[ind][1],
          y = rects[ind][2],
          w = rects[ind][3],
          h = rects[ind][4],
          id = rects[ind][5]
        })
				rects[ind] = nil
      end 
    end
  end
  exit = physicsChannel:pop()
end
