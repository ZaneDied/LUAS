local wln, wht
local TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh
local StartButx, StartButy, StartButw, StartButh

--- Text
local MTHeight, MTWidth, MenuF
local Mtext = "MENU"

--- Image
local mycomp, mycompw, mycomph
local networking, networkingw, networkingh
local inbox, inboxw, inboxh
local briefcase, briefcasew, briefcaseh

function love.load()

    love.graphics.setBackgroundColor(0,130/250,130/250)
    -- 970 to 97 to 10
    -- 570 to 57 to 10
    wln = love.graphics.getWidth() -- Window length
    wht = love.graphics.getHeight() -- Window Height

    --- Image
    mycomp = love.graphics.newImage("w2k-computer-6.png") -- image computer
    mycomph = mycomp:getHeight()
    mycompw = mycomp:getWidth()

    networking = love.graphics.newImage("w2k_network_computer-5.png")
    networkingh = networking:getHeight()
    networkingw = networking:getWidth()

    inbox = love.graphics.newImage("w98_mailbox_world-3.png")
    inboxh = inbox:getHeight()
    inboxw = inbox:getWidth()

    briefcase = love.graphics.newImage("w98_briefcase-5.png")
    briefcaseh = briefcase:getHeight()
    briefcasew = briefcase:getWidth()

    ----
    MenuF = love.graphics.newFont(15)
    love.graphics.setFont(MenuF)
    MTWidth = MenuF:getWidth(Mtext)
    MTHeight = MenuF:getHeight(Mtext)
    ----

    ---- TaskBar
    TaskBarStartx = 0
    TaskBarStarty = wht - 50
    TaskBarEndw = wln
    TaskBarEndh = 50
    ----

    --- Start Menu button
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
    love.graphics.line(0, TaskBarStarty + 3, TaskBarEndw, TaskBarStarty + 3)
    
   
    love.graphics.setColor(1, 1, 1) -- Draw the start button's border (line)
    love.graphics.rectangle("line", StartButx, StartButy, StartButw, StartButh)

    
    love.graphics.setColor(0, 0, 0) -- Draw the black line (This line was causing the error)
    love.graphics.line(StartButx, StartButy + StartButh, StartButx + StartButw, StartButy + StartButh, StartButx + StartButw, StartButy)
    

    --love.graphics.print(text (string), x (number), y (number), r (number), sx (number), sy (number), ox (number), oy (number), kx (number), ky (number))
    love.graphics.print(Mtext, StartButx + (StartButw / 2), StartButy + (StartButh / 2), 0, 1, 1, MTWidth / 2, MTHeight / 2)
    
   
    love.graphics.setColor(1, 1, 1)  --- Image drawing

    --love.graphics.draw(drawable (Drawable), x (number), y (number), r (number), sx (number), sy (number), ox (number), oy (number), kx (number), ky (number))
    -- 51  
    --love.graphics.draw(mycomp, 51 / 2, mycomph, 0, 1, 1, mycompw / 2, mycomph / 2)
    love.graphics.draw(mycomp, 40, 10, 0, 1 , 1, mycompw/2)

    love.graphics.draw(networking, 40, mycomph + 25, 0, 1, 1, networkingw/2)

    --love.graphics.draw(inbox, 51 / 2, 0, 0, 1, 1, inboxw / 2, inboxh / 2)

    --love.graphics.draw(briefcase, 51 / 2, 0, 0, 1, 1, briefcasew / 2, briefcaseh / 2)
    


    love.graphics.setColor(1, 1, 1)
end