leaf = {}
leaf.CVER = "1.3.2"

-- Skip components --
leaf.__unload = {}
function leaf.skip(...)

    local comps = {...}

    for _, c in pairs(comps) do

            if c == 'resources' then leaf.skip_res = true
        elseif c == 'drawtiles' then leaf.skip_dtm = true
        elseif c == 'drawtexts' then leaf.skip_dtx = true
        else leaf.__unload[c] = true end
    end
end

if love then

    local ldd, _w, _h, _s, _rz, _mw, _mh, _vs
    function leaf.init(w, h, s, rz, mw, mh, vs)

        _w, _h, _s, _rz, _mw, _mh, _vs = w, h, s, rz, mw, mh, vs
        ldd = true
    end

    -- Screen configuration --
    function leaf._init(w, h, s, mv, rz, mw, mh, vs)

        if rz == nil then rz = true end
        if vs == nil then vs = true end

        local min_w = w / (s * 2)
        local min_h = h / (s * 2)

        leaf.SSCALE = s or 1
        leaf.s_wdth = w / leaf.SSCALE
        leaf.s_hght = h / leaf.SSCALE

        love.window.setMode(w, h, {

            resizable = rz,
            vsync     = vs,
            minwidth  = mw or min_w,
            minheight = mh or min_h,
        })

        -- Fix resolution --
        love.graphics.setDefaultFilter('nearest')

        -- Mouse is visible --
        if mv ~= nil then love.mouse.setVisible(mv) end

        -- Resources --
        if not leaf.skip_res then

            local h_sheet = love.filesystem.getInfo('resources/sprites.png')
            local h_tiled = love.filesystem.getInfo('resources/tilemap.png')

            assert(not (not h_sheet and not h_tiled),
            'Missing base resource files (sprite sheet and tilemap palette)')

            assert(h_sheet, 'Missing base resource file (sprite sheet)')
            assert(h_tiled, 'Missing base resource file (tilemap palette)')

            leaf.sheet = love.graphics.newImage('resources/sprites.png')
            leaf.tiled = love.graphics.newImage('resources/tilemap.png')
        end

        -- Set random seed --
        math.randomseed(os.time() + w * h)
    end

    function leaf.preload(...)

        local comps = {...}

        for _, c in pairs(comps) do

            dofile('leaf/leaf_' .. c .. '.lua')
            leaf.__unload[c] = true
        end
    end

    -- Input --
    leaf.inputs = {}
    leaf.inputs.prss = {}
    leaf.inputs.rlss = {}

    function love.keypressed(key)
        -- Close program --
        if  key == "escape"
        and love.window.hasFocus() then

            local exit
            if leaf.kill then

                exit = leaf.kill()

            else exit = true end

            if exit then

                love.event.quit()
            end
        end

        leaf.inputs.prss[key] = true
    end

    function leaf.btn(key)

        return love.keyboard.isDown(key)
    end

    function leaf.btnp(key)
        -- Return if is empty key --
        if key == '' then return end

        local out = leaf.inputs.prss[key]
        return out
    end

    function love.keyreleased(key)

        leaf.inputs.rlss[key] = true
    end

    function leaf.btnr(key)
        -- Return if is empty key --
        if key == '' then return end

        local out = leaf.inputs.rlss[key]
        return out
    end

    -- leaf workflow --
    function love.load()

        local lddl = {'core', 'audiofx', 'physics', 'renderer', 'storange'}

        for _, lib in pairs(lddl) do

            if not leaf.__unload[lib] then

                dofile('leaf/leaf_' .. lib .. '.lua')
            end
        end

        -- Call sub initializer --
        if ldd then

            leaf._init(_w, _h, _s, _rz, _mw, _mh, _vs)
        -- If not called, replace sub with main --
        else leaf.init = leaf._init end

        leaf.ready = true

        if leaf.load then leaf.load() end
    end

    function love.update(dt)
        -- Current fps --
        leaf.fps = love.timer.getFPS()
        leaf.mem = collectgarbage('count') / 1024

        -- Update Screen sizw --
        leaf.s_wdth = love.graphics.getWidth()  / leaf.SSCALE
        leaf.s_hght = love.graphics.getHeight() / leaf.SSCALE

        -- Leaf global step --
        if leaf.step then leaf.step(dt) end
        if leaf.late then leaf.late()   end

        leaf.inputs.prss = {}
        leaf.inputs.rlss = {}
    end

    function love.draw()

        local scale = love.graphics.getWidth() / leaf.s_wdth
        -- update the drawing --
        -- scale according to --
        -- the screen size    --
        love.graphics.scale(scale, scale)
        -- draw internal objects --
            if leaf.draw_text and
           not leaf.skip_dtx then leaf.draw_text() end
        if not leaf.skip_dtm then leaf.draw_tilemap() end

        if leaf.draw then leaf.draw() end
    end
end
