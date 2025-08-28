local wln
local wht
local myFont
local TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh
local LightBarStartx, LightBarStarty
local StartButx, StartButy, StartButw, StartButh
local textHeight, textWidth
local text = "MENU"
local mycomp


function love.load()
    love.graphics.setBackgroundColor(0,130/250,130/250)
    -- 970 to 97 to 10
    -- 570 to 57 to 10
    wln = love.graphics.getWidth() -- Window length
    wht = love.graphics.getHeight() -- Window Height

    mycomp = love.graphics.newImage("w2k-computer.png")

    myFont = love.graphics.newFont(20)
    love.graphics.setFont(myFont)
    textWidth = myFont:getWidth(text)
    textHeight = myFont:getHeight(text)


    TaskBarStartx = 0
    TaskBarStarty = wht - 50
    TaskBarEndw = wln
    TaskBarEndh = 50

    LightBarStartx = 0
    LightBarStarty = TaskBarStarty + 3


    StartButx = 10
    StartButy = TaskBarStarty + 7
    StartButw = 70
    StartButh = 40
    

end

function love.update(dt)
    mouseX = love.mouse.getX()
    mouseY = love.mouse.getY()
    print( mouseX , mouseY)
end

function love.draw()

    love.graphics.setColor(195/255, 195/255, 195/255) -- Draw the taskbar (fill)
    love.graphics.rectangle("fill", TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh)
    
    
    love.graphics.setColor(1, 1, 1) -- Draw the light bar (line)
    love.graphics.line(LightBarStartx, LightBarStarty, TaskBarEndw, LightBarStarty)
    
   
    love.graphics.setColor(1, 1, 1) -- Draw the start button's border (line)
    love.graphics.rectangle("line", StartButx, StartButy, StartButw, StartButh)

    
    love.graphics.setColor(0, 0, 0) -- Draw the black line (This line was causing the error)
    love.graphics.line(StartButx, StartButy + StartButh, StartButx + StartButw, StartButy + StartButh, StartButx + StartButw, StartButy)
    

    --love.graphics.print(text (string), x (number), y (number), r (number), sx (number), sy (number), ox (number), oy (number), kx (number), ky (number))
    love.graphics.print(text, StartButx + (StartButw / 2), StartButy + (StartButh / 2), 0, 1, 1, textWidth / 2, textHeight / 2)

    love.graphics.draw(mycomp, 100, 100)

    love.graphics.setColor(1, 1, 1)

end