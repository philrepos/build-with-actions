-- main.lua

-- GAME VARIABLES
local player = { x = 0, y = 0, size = 30, velocity = 0, rotation = 0 }
local gravity = 1500
local jumpHeight = -500
local pipes = {}
local pipeWidth = 60
local pipeGap = 200
local pipeSpeed = 200
local spawnTimer = 0
local spawnRate = 2
local score = 0
local gameState = "start"
local screenW, screenH

-- FONTS
local gameFont

function love.load()
    love.window.setMode(400, 600, {resizable=true, minwidth=300, minheight=400})
    love.window.setTitle("Flappy Square")

    -- Initialize random seed
    math.randomseed(os.time())

    -- Force a resize calculation immediately to set up fonts and player pos
    resizeGame(love.graphics.getWidth(), love.graphics.getHeight())

    resetGame()
end

-- This function runs automatically whenever the window size changes
function love.resize(w, h)
    resizeGame(w, h)
end

function resizeGame(w, h)
    screenW = w
    screenH = h

    -- Create a font that is 5% of the screen height (Dynamic Text!)
    local fontSize = math.floor(h * 0.05)
    gameFont = love.graphics.newFont(fontSize)

    -- If we are in the start menu, keep player nicely positioned
    if gameState == "start" then
        player.x = screenW * 0.2
        player.y = screenH / 2
    end
end

function resetGame()
    player.y = screenH / 2
    player.x = screenW * 0.2
    player.velocity = 0
    player.rotation = 0

    pipes = {}
    score = 0
    spawnTimer = 0
    gameState = "start"
end

function love.update(dt)
    if gameState == "playing" then
        -- 1. Apply Gravity
        player.velocity = player.velocity + gravity * dt
        player.y = player.y + player.velocity * dt

        -- 2. Calculate Rotation (Visual Polish)
        -- Map velocity to rotation: Up = negative angle, Down = positive angle
        -- We clamp it so it doesn't spin 360 degrees
        player.rotation = player.velocity * 0.001
        if player.rotation > 1 then player.rotation = 1 end
        if player.rotation < -0.5 then player.rotation = -0.5 end

        -- 3. Check Floor/Ceiling collision
        if player.y > screenH or player.y < 0 then
            gameState = "dead"
        end

        -- 4. Manage Pipes
        spawnTimer = spawnTimer + dt
        if spawnTimer > spawnRate then
            spawnPipe()
            spawnTimer = 0
        end

        for i, pipe in ipairs(pipes) do
            pipe.x = pipe.x - pipeSpeed * dt

            if checkCollision(player, pipe) then
                gameState = "dead"
            end

            if not pipe.passed and pipe.x < player.x then
                score = score + 1
                pipe.passed = true
            end
        end

        -- Cleanup old pipes
        for i = #pipes, 1, -1 do
            if pipes[i].x < -pipeWidth then
                table.remove(pipes, i)
            end
        end
    end
end

function spawnPipe()
    local minH = screenH * 0.2
    local maxH = screenH * 0.8
    local gapCenterY = math.random(minH, maxH)

    table.insert(pipes, {
        x = screenW,
        gapTop = gapCenterY - (pipeGap / 2),
        gapBottom = gapCenterY + (pipeGap / 2),
        passed = false
    })
end

function checkCollision(p, pipe)
    -- We use a slightly smaller hitbox than the visual size
    -- to make the game feel fairer (grace area)
    local hitbox = 4

    if (p.x + p.size - hitbox > pipe.x) and (p.x + hitbox < pipe.x + pipeWidth) then
        if (p.y + hitbox < pipe.gapTop) or (p.y + p.size - hitbox > pipe.gapBottom) then
            return true
        end
    end
    return false
end

function love.mousepressed(x, y, button)
    if gameState == "start" then
        gameState = "playing"
        player.velocity = jumpHeight
    elseif gameState == "playing" then
        player.velocity = jumpHeight
    elseif gameState == "dead" then
        resetGame()
    end
end

-- Handle Android Back Button (Key "escape")
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    -- Allow spacebar to jump on PC
    if key == "space" then
        love.mousepressed(0,0,1)
    end
end

function love.draw()
    love.graphics.setFont(gameFont)

    -- Draw Background
    love.graphics.clear(0.1, 0.1, 0.2)

    -- Draw Player with Rotation
    -- To rotate a rectangle, we have to move the "camera" to the player center,
    -- rotate the world, draw the square, then put the camera back.
    love.graphics.push()
    love.graphics.translate(player.x + player.size/2, player.y + player.size/2)
    love.graphics.rotate(player.rotation)
    love.graphics.setColor(1, 0.8, 0)
    -- Draw offset by half size so it centers on the coordinate
    love.graphics.rectangle("fill", -player.size/2, -player.size/2, player.size, player.size)
    love.graphics.pop()

    -- Draw Pipes
    love.graphics.setColor(0.3, 0.8, 0.3)
    for _, pipe in ipairs(pipes) do
        love.graphics.rectangle("fill", pipe.x, 0, pipeWidth, pipe.gapTop)
        love.graphics.rectangle("fill", pipe.x, pipe.gapBottom, pipeWidth, screenH - pipe.gapBottom)
    end

    -- Draw Text
    love.graphics.setColor(1, 1, 1)
    if gameState == "start" then
        love.graphics.printf("TAP TO START", 0, screenH/2 - (screenH*0.1), screenW, "center")
    elseif gameState == "dead" then
        love.graphics.printf("GAME OVER\nScore: " .. score, 0, screenH/2 - (screenH*0.1), screenW, "center")
    else
        love.graphics.print(score, 20, 20)
    end
end
