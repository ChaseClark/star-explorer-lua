-- Chase Clark, 11/13/16

-- initial settings
display.setStatusBar(display.HiddenStatusBar)
system.activate("multitouch")
local physics = require("physics")
physics.start()
physics.setGravity(0,0)

-- variables
local w = display.contentWidth
local h = display.contentHeight
local background = display.newImage("images/bg1.png",true)
background.x = w/2
background.y = h/2

local lives = 3
local score = 0
local numShot = 0
local shotTable = {}
local asteroidsTable = {}
local numAsteroids = 0
local maxShotAge = 1000
local tick = 400 --time between game loops in milliseconds
local died = false

--audio
local explosion = audio.loadSound("sounds/explosion.wav")
local fire = audio.loadSound("sounds/fire.wav")
local music = audio.loadStream("sounds/space-music.mp3")

-- Displays lives and score
local function newText()
    textLives = display.newText("Lives: "..lives, w/2, 30, nil, 12)
    textScore = display.newText("Score: "..score, w/2, 10, nil, 12)
    textLives:setFillColor(1,1,1)
    textScore:setFillColor(1,1,1)
end

local function updateText()
    textLives.text = "Lives: "..lives
    textScore.text = "Score: "..score
end

-- dragging physics
local function startDrag(event)
    local t = event.target

    local phase = event.phase
    if "began" == phase then
        display.getCurrentStage():setFocus(t)
        t.isFocus = true

        --Store initial position
        t.x0 = event.x - t.x
        t.y0 = event.y - t.y

        event.target.bodyType = "kinematic"

        --stop current motion
        event.target:setLinearVelocity(0,0)
        event.target.angularVelocity = 0

    elseif t.isFocus then
        if "moved" == phase then
            t.x = event.x - t.x0
            t.y = event.y - t.y0
        elseif "ended" == phase or "cancelled" == phase then
            display.getCurrentStage():setFocus(nil)
            t.isFocus = false

            -- switch body type back to "dynamic"
            if (not event.target.isPlatform) then
                event.target.bodyType = "dynamic"
            end
        end
    end
    return true
end

-- ship spawn
local function spawnShip()
    ship = display.newImage("images/newship.png")
    ship.x = w/2
    ship.y = h - 50
    physics.addBody(ship, {density=1.0, bounce=1.0})
    ship.myName="ship"
    ship.isFixedRotation = true
end

local function loadAsteroid()
    numAsteroids = numAsteroids + 1
    asteroidsTable[numAsteroids] = display.newImage("images/asteroids1-1a.png")

    physics.addBody(asteroidsTable[numAsteroids],{density=1,friction=0.4,bounce=1})
    local whereFrom = math.random(3)
    asteroidsTable[numAsteroids].myName = "asteroid"
    
    if(whereFrom==1) then
        asteroidsTable[numAsteroids].x = -50
        asteroidsTable[numAsteroids].y = (math.random(h * .75))

        transition.to(asteroidsTable[numAsteroids],
{x=(w+100),y=(math.random(h)),time=(math.random(5000,10000))})

    elseif (whereFrom==2) then
        asteroidsTable[numAsteroids].x = (math.random(w))

        asteroidsTable[numAsteroids].y = -30

        transition.to(asteroidsTable[numAsteroids],
{x=(math.random(w)),y=(h+100),time=(math.random(5000,10000))})

    elseif (whereFrom==3) then
        asteroidsTable[numAsteroids].x = w+50

        asteroidsTable[numAsteroids].y = (math.random(h*.75))

        transition.to(asteroidsTable[numAsteroids],
{x=-100,y=(math.random(h)),time=(math.random(5000,10000))})
    end

end

-- collision

local function onCollision(event)
    if(event.object1.myName == "ship" or event.object2.myName == "ship") then
        if (died == false) then
            died = true
            if (lives == 1) then
                audio.play(explosion)
                event.object1:removeSelf()
                event.object2:removeSelf()
                lives = lives - 1
                local lose = display.newText("You Have Failed.", w/2, 150, nil, 36)
                lose:setFillColor(1,1,1)
            else 
                audio.play(explosion)
                ship.alpha = 0
                lives = lives -1
                cleanup()
                timer.performWithDelay(2000,weDied,1)
            end
        end
    end
    if (event.object1.myName == "asteroid" and event.object2.myName == "shot")
or (event.object1.myName == "shot" and event.object2.myName == "asteroid") then
        audio.play(explosion)
        event.object1:removeSelf()
        event.object1.myName = nil
        event.object2:removeSelf()
        event.object2.myName = nil
        score = score + 100
    end

end

function weDied()
    --fade in the new ship
    ship.x=w/2
    ship.y=h - 50
    transition.to(ship, {alpha=1, timer=2000})
    died = false
end

local function fireShot(event)
    numShot = numShot + 1
    shotTable[numShot] = display.newImage("images/bullet.png")
    physics.addBody(shotTable[numShot], {density=1,friction=0})
    shotTable[numShot].isBullet = true
    shotTable[numShot].x=ship.x
    shotTable[numShot].y=ship.y-60
    transition.to(shotTable[numShot],{y=-80, time=700})
    audio.play(fire)
    shotTable[numShot].myName="shot"
    shotTable[numShot].age=0
end

function cleanup()
    for i=1,table.getn(asteroidsTable) do
        if(asteroidsTable[i].myName~=nil) then
            asteroidsTable[i]:removeSelf()
            asteroidsTable[i].myName=nil
        end
    end
    for i=1,table.getn(shotTable) do
        if(shotTable[i].myName~=nil) then
            shotTable[i]:removeSelf()
            shotTable[i].myName=nil
        end
    end
end

local function gameLoop()
    updateText()
    loadAsteroid()
    --remove old shots fired so they dont stack
    for i = 1, table.getn(shotTable) do
        if (shotTable[i].myName ~= nil and shotTable[i].age < maxShotAge) then
            shotTable[i].age = shotTable[i].age + tick
        elseif (shotTable[i].myName ~= nil) then
            shotTable[i]:removeSelf()
            shotTable[i].myName=nil
        end
    end
end


local playButton = display.newImage("images/play.png", w-50, 10)
--toggle button for background song
local isPlaying = false
local function playMusic(event)
	if isPlaying then
        audio.stop()
        isPlaying = false
    else
        audio.play(music)
        isPlaying = true
    end
end

--Start the game
spawnShip()
newText()

ship:addEventListener("touch",startDrag)
ship:addEventListener("tap",fireShot)
Runtime:addEventListener("collision",onCollision)
playButton:addEventListener("tap", playMusic)

timer.performWithDelay(tick, gameLoop, 0)