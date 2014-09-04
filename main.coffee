# package import
Shape = createjs.Shape
Graphics = createjs.Graphics
Container = createjs.Container
Stage = createjs.Stage

cardWidth = 81
cardHeight = 113

NO_INTERNET = false

imgPool = {}

getImage = (str) ->
        if str of imgPool
                return imgPool[str]
        img = new Image()
        img.src = str
        img.onerror = -> img.src = "cardback.jpg"
        imgPool[str] = img
        return img

getCardImage = (card) ->
        return getImage(encodeURI(card) + ".full.jpg")

parseMWDeck = (str) ->
        deck = []
        lines = str.split("\n")
        for line in lines
                ix = line.indexOf("//")
                if ix != -1
                        line = line.substr(0, line.indexOf("//"))
                line = line.trim()
                if line.length == 0
                        continue
                st = line.split(" ")
                if st[0] == "SB:"
                        continue
                cardName = st[1].substr(1, 3) + "/"
                for i in [2..(st.length-1)]
                        if st[i][0] == "("
                                cardName += st[i][1]
                                console.log("land:", cardName)
                                break
                        if i != 2
                                cardName += " "
                        cardName += st[i]

                for i in [1..parseInt(st[0])]
                        deck.push(cardName)
        return deck

mwdeck = """
4 [JOU] Mana Confluence
4 [JOU] Temple of Malady
4 [BNG] Temple of Plenty
4 [THS] Temple of Silence
4 [M15] Forest (1)
3 [M15] Swamp (1)
2 [M15] Plains (1)
4 [THS] Sylvan Caryatid
4 [THS] Fleecemane Lion
4 [BNG] Brimaz, King of Oreskos
4 [BNG] Courser of Kruphix
2 [THS] Polukranos, World Eater
4 [THS] Hero's Downfall
3 [THS] Thoughtseize
1 [JOU] Banishing Light
4 [JOU] Silence the Believers
1 [THS] Read the Bones
4 [THS] Elspeth, Sun's Champion

SB: 2 [THS] Glare of Heresy
SB: 2 [JOU] Deicide
SB: 1 [THS] Gods Willing
SB: 2 [THS] Boon Satyr
SB: 2 [THS] Arbor Colossus
SB: 2 [BNG] Drown in Sorrow
SB: 1 [THS] Read the Bones
SB: 1 [THS] Thoughtseize
SB: 1 [JOU] Feast of Dreams
SB: 1 [BNG] Bile Blight
"""

shuffle = (deck) ->
        n = deck.length
        for i in [(n-1)..1]
                j = ~~(Math.random() * i)
                tmp = deck[i]
                deck[i] = deck[j]
                deck[j] = tmp

stage = null
deck = null
tokenList = []
table = null
contextMenu = null

randomColor = ->
        r = ~~(Math.random() * 256)
        g = ~~(Math.random() * 256)
        b = ~~(Math.random() * 256)
        return "rgb(#{r},#{g},#{b})"

setClickListeners = (target, onClick, onRightClick) ->
        if not createjs.Touch.isSupported()
                target.on("mousedown", (evt) ->
                        if evt.nativeEvent.button == 0
                                onClick(evt)
                        else if evt.nativeEvent.button == 2
                                onRightClick(evt)
                )
        else
                target.on("mousedown", (evt) ->
                        @rightClicked = false
                        @timerID = setInterval(() =>
                                @rightClicked = true
                                clearInterval(@timerID)
                                onRightClick(evt)                                
                        , 500)
                )
                target.on("pressup", (evt) ->
                        if not @rightClicked
                                clearInterval(@timerID)
                                onClick(evt)
                )

makeContextMenu = (menuList, onClickListener) ->
        c = new createjs.Container()
        bg = new Shape(new Graphics().beginFill("rgb(240,240,240)").rect(0,0,180, 28 * menuList.length))
        bg.shadow = new createjs.Shadow(4, "gray", 4, 4)
        c.addChild(bg)

        for menu, i  in menuList
                r = new Shape(new Graphics().beginFill("rgb(240,240,240)").rect(0, 0,180, 28))
                r.x = 0
                r.y = i * 28
                c.addChild(r)                
                t = new createjs.Text(menu, "bold 24px Arial", "black")
                t.x = 0
                t.y = i * 28
                c.addChild(t)
                onMouseOver = do (r, t) -> (evt) ->
                        r.graphics.clear().beginFill("rgb(39,23,88)").rect(0, 0, 180, 28)
                        t.color = "white"
                r.on("mouseover", onMouseOver)
                t.on("mouseover", onMouseOver)
                onMouseOut = do (r, t) -> (evt) ->
                                r.graphics.clear().beginFill("rgb(240,240,240)").rect(0, 0, 180, 28)
                                t.color = "black"
                r.on("mouseout", onMouseOut)
                t.on("mouseout", onMouseOut)
                onMouseDown = do (i) -> (evt) -> onClickListener(i)
                r.on("mousedown", onMouseDown)
                t.on("mousedown", onMouseDown)

        return c

showContextMenu = (x, y, menuList, onClickListener) ->
        contextMenu = makeContextMenu(menuList, onClickListener)
        contextMenu.x = x
        contextMenu.y = y        
                
        dummy = new Shape(new Graphics().beginFill("rgba(0,0,0,0.01)").rect(0,0,1200,800))

        removeContextMenu = (evt) ->
                console.log("hoge")
                if contextMenu?
                        stage.removeChild(contextMenu)
                        stage.removeChild(dummy)
                        contextMenu = null

        contextMenu.addEventListener("mousedown", removeContextMenu)
        dummy.addEventListener("mousedown", removeContextMenu)

        stage.addChild(dummy)
        stage.addChild(contextMenu)

counterImageFile = (n) ->
        "counter/icon_number02_orange14_" + ("0"+n).slice(-2) + ".gif"
        
makeCounter = (n) ->
        bmp = new createjs.Bitmap(getImage(counterImageFile(n)))
        bmp.count = n
        bmp.incr = -> bmp.image = getImage(counterImageFile(++bmp.count))
        bmp.decr = -> bmp.image = getImage(counterImageFile(--bmp.count))
        setClickListeners(bmp, ((evt) -> bmp.incr()), (evt) ->
                if bmp.count == 1
                        bmp.parent.removeChild(bmp)
                else
                        bmp.decr()
        )
        return bmp

enableDrag = (target, onClick) ->
        target.on("pressup", (evt) ->
                if Math.sqrt(Math.pow(@dragStart.x - evt.stageX, 2) + Math.pow(@dragStart.y - evt.stageY, 2)) < 3
                        onClick.call(target, evt))

        target.addEventListener("mousedown", (evt) ->
                if not target.parent?
                        return
                target.parent.addChild(target)
                target.offset =
                        x: target.x - evt.stageX
                        y: target.y - evt.stageY
                target.dragStart =
                        x: evt.stageX
                        y: evt.stageY
        )
        target.on("pressmove", (evt) ->
                @x = evt.stageX + @offset.x
                @y = evt.stageY + @offset.y
        )

addCardToField = (bmp) ->
        enableDrag(bmp, (evt) -> @rotation = (@rotation + 90) % 180)
        table.addChild(bmp)

drawCard = ->
        if deck.length == 0
                alert("library out!!!")
                return
        card = deck.pop()
        console.log(card)

        cardDrawX = 170
        for elem in table.children
                if elem.y > 660 and elem.x + cardWidth + 10 > cardDrawX and elem.x < 830
                        cardDrawX = elem.x + cardWidth + 10
        
        bmp =
                if !NO_INTERNET
                        img = getCardImage(card)
                        console.log(img)
                        bmp = new createjs.Bitmap(img)
                        bmp
                else
                        new Shape(new Graphics().beginFill(randomColor()).rect(0, 0, cardWidth, cardHeight))

        bmp.regX = cardWidth / 2 #
        bmp.regY = cardHeight / 2 #
        bmp.x = cardDrawX
        bmp.y = 670 + bmp.regY
        addCardToField(bmp)

showDeck = ->
        margin = 80
        padding = 30
        w = canvas.width - margin * 2
        h = canvas.height - margin * 2
        layer = new createjs.Container()
        layer.x = margin
        layer.y = margin
        
        box = new Shape(new Graphics().beginFill("rgb(188,188,188)").rect(0, 0, w, h))
        box.shadow = new createjs.Shadow("black", 5, 5, 10)
        layer.addChild(box)
        
        layer.addChild(new Shape(new Graphics().beginFill("rgb(128,128,128)").rect(0, 0, w, 30)))
        layer.addChild(new Shape(new Graphics().setStrokeStyle(6).beginStroke("rgb(64,64,64)").moveTo(w-20, 5).lineTo(w-5, 20)))
        layer.addChild(new Shape(new Graphics().setStrokeStyle(6).beginStroke("rgb(64,64,64)").moveTo(w-20, 20).lineTo(w-5, 5)))

        row = ~~((w - padding - cardWidth) / cardWidth) #
        num_row = ~~(deck.length / row) + 1 #
        step = ~~((h - padding * 2 - cardHeight) / num_row) #
        console.log("row:", row)
        console.log("num_row:", num_row)
        for card, i in deck
                x = padding + ~~(i / num_row) * cardWidth #
                y = padding * 2 + step * (i % num_row)
                bmp = new createjs.Bitmap(getCardImage(card))
                bmp.x = x
                bmp.y = y
                bmp.card = card
                bmp.on("mousedown", (evt) ->
                        @parent.addChild(@)
                        @offset =
                                x: @x - evt.stageX
                                y: @y - evt.stageY
                )
                bmp.on("pressmove", (evt) ->
                        @x = evt.stageX + @offset.x
                        @y = evt.stageY + @offset.y
                )
                bmp.on("pressup", (evt) ->
                        if @x < 0 or @y < 0 or @x + cardWidth > w or @y + cardHeight > h
                                @parent.removeChild(@)
                                if deck.indexOf(@card) != -1
                                        deck.splice(deck.indexOf(@card), 1)
                                        bmp = new createjs.Bitmap(getCardImage(@card))
                                        bmp.regX = cardWidth / 2 #
                                        bmp.regY = cardHeight / 2 #
                                        bmp.x = @x + margin + bmp.regX
                                        bmp.y = @y + margin + bmp.regY
                                        addCardToField(bmp)
                )
                layer.addChild(bmp)

        layer.on("pressup", (evt) ->
                console.log(evt)
                console.log(evt.x)
                console.log(evt.y)
                if evt.localX > w - 20 && evt.localY < 20
                        stage.removeChild(layer)
        )
        stage.addChild(layer)

showToken = ->
        margin = 80
        padding = 30
        w = canvas.width - margin * 2
        h = canvas.height - margin * 2
        layer = new createjs.Container()
        layer.x = margin
        layer.y = margin
        
        box = new Shape(new Graphics().beginFill("rgb(188,188,188)").rect(0, 0, w, h))
        box.shadow = new createjs.Shadow("black", 5, 5, 10)
        layer.addChild(box)
        
        layer.addChild(new Shape(new Graphics().beginFill("rgb(128,128,128)").rect(0, 0, w, 30)))
        layer.addChild(new Shape(new Graphics().setStrokeStyle(6).beginStroke("rgb(64,64,64)").moveTo(w-20, 5).lineTo(w-5, 20)))
        layer.addChild(new Shape(new Graphics().setStrokeStyle(6).beginStroke("rgb(64,64,64)").moveTo(w-20, 20).lineTo(w-5, 5)))

        row = ~~((w - padding - cardWidth) / cardWidth) #
        num_row = ~~(tokenList.length / row) + 1 #
        step = ~~((h - padding * 2 - cardHeight) / num_row) #
        console.log("row:", row)
        console.log("num_row:", num_row)
        for card, i in tokenList
                for j in [0...10]
                        x = padding + ~~(i / num_row) * cardWidth #
                        y = padding * 2 + step * (i % num_row)
                        bmp = new createjs.Bitmap(getCardImage(card))
                        bmp.x = x
                        bmp.y = y
                        bmp.card = card
                        bmp.on("mousedown", (evt) ->
                                @parent.addChild(@)
                                @offset =
                                        x: @x - evt.stageX
                                        y: @y - evt.stageY
                        )
                        bmp.on("pressmove", (evt) ->
                                @x = evt.stageX + @offset.x
                                @y = evt.stageY + @offset.y
                        )
                        bmp.on("pressup", (evt) ->
                                if @x < 0 or @y < 0 or @x + cardWidth > w or @y + cardHeight > h
                                        @parent.removeChild(@)
                                        bmp = new createjs.Bitmap(getCardImage(@card))
                                        bmp.regX = cardWidth / 2 #
                                        bmp.regY = cardHeight / 2 #
                                        bmp.x = @x + margin + bmp.regX
                                        bmp.y = @y + margin + bmp.regY
                                        addCardToField(bmp)
                        )
                        layer.addChild(bmp)

        layer.on("pressup", (evt) ->
                console.log(evt)
                console.log(evt.x)
                console.log(evt.y)
                if evt.localX > w - 20 && evt.localY < 20
                        stage.removeChild(layer)
        )
        stage.addChild(layer)

scry1 = ->
        card = deck.pop()
        c = new Container()
        c.x = 90
        c.y = 470
        balloon = new createjs.Bitmap("balloon.png")
        c.addChild(balloon)
        bmp = new createjs.Bitmap(getCardImage(card))
        bmp.x = 21
        bmp.y = 10
        c.addChild(bmp)
        btn_top = new createjs.Bitmap("button_top.png")
        btn_top.x = 28
        btn_top.y = 125
        btn_top.on("mousedown", (evt) ->
                stage.removeChild(c)
                deck.push(card)
        )
        c.addChild(btn_top)
        btn_bottom = new createjs.Bitmap("button_bottom.png")
        btn_bottom.x = 10
        btn_bottom.y = 162
        btn_bottom.on("mousedown", (evt) ->
                stage.removeChild(c)
                deck.unshift(card)
        )
        c.addChild(btn_bottom)
        stage.addChild(c)

untapAll = ->
        for o in table.children
                o.rotation = 0 if o.rotation?

init = (canvas) ->

        deck = parseMWDeck(mwdeck)
        shuffle(deck)

        canvas.oncontextmenu = (e) =>
                e.preventDefault()
                return false

        stage = new createjs.Stage(canvas)
        stage.enableMouseOver(100)
        createjs.Touch.enable(stage)

        table = new createjs.Container()
        tableAbove = new createjs.Container()
        stage.addChild(table)
        stage.addChild(tableAbove)

        tableBg = new Shape(new Graphics().beginFill("rgb(222,222,222)").rect(0, 0, canvas.width, canvas.height))
        setClickListeners(tableBg, ((evt) -> return), (evt) -> showContextMenu(evt.localX, evt.localY, ["counter", "token"], (i) ->
                if i == 0
                        counter = makeCounter(1)
                        counter.x = evt.localX
                        counter.y = evt.localY
                        enableDrag(counter, (evt) -> return)
                        tableAbove.addChild(counter)
                else if i == 1
                        showToken()
        ))
        table.addChild(tableBg)
        handBorder1 = new Shape(new Graphics().beginStroke("rgb(111,111,111)").moveTo(10, 140).lineTo(850, 140))
        handBorder1.shadow = new createjs.Shadow("black",1,5,5) 
        table.addChild(handBorder1)
        table.addChild(new Shape(new Graphics().beginStroke("rgb(111,111,111)").moveTo(10, 400).lineTo(850, 400)))
        handBorder2 = new Shape(new Graphics().beginStroke("rgb(111,111,111)").moveTo(10, 660).lineTo(850, 660))
        handBorder2.shadow = new createjs.Shadow("black",1,-5,5)
        table.addChild(handBorder2)
        table.addChild(new Shape(new Graphics().beginStroke("rgb(111,111,111)").moveTo(860, 10).lineTo(860, canvas.height - 10)))

        trashBmp = new createjs.Bitmap("trash.png")
        trashBmp.regX = cardWidth / 2 #
        trashBmp.regY = cardHeight / 2 #
        trashBmp.x = 10 + trashBmp.regX
        trashBmp.y = 550 + trashBmp.regY
        table.addChild(trashBmp)

        exileBmp = new createjs.Bitmap("exile.png")
        exileBmp.regX = cardWidth / 2 #
        exileBmp.regY = cardHeight / 2 #
        exileBmp.x = 20 + exileBmp.regX
        exileBmp.y = 450 + exileBmp.regY
        table.addChild(exileBmp)
                
        deckBmp = new createjs.Bitmap("cardback.jpg")

        deckBmp.regX = cardWidth / 2 #
        deckBmp.regY = cardHeight / 2 #
        deckBmp.x = 10 + deckBmp.regX
        deckBmp.y = 670 + deckBmp.regY

        console.log(deckBmp)
        
        setClickListeners(deckBmp, ((evt) -> drawCard()), (evt) ->
                showContextMenu(evt.stageX + 3, evt.stageY + 3, ["Draw", "Search", "Scry 1"], (i) ->
                        if i == 0
                                drawCard()
                        if i == 1
                                showDeck()
                        if i == 2
                                scry1()
                )
        )
        table.addChild(deckBmp)

        button1 = new createjs.Text("Search deck (s)", "bold 24px Arial", "black")
        button1.x = 870
        button1.y = 770
        button1.hitArea = new Shape(new Graphics().beginFill("rgba(255,0,0,100)").rect(0,0,200,50))
        button1.on("pressup", (evt) ->
                showDeck()
        )

        button2 = new createjs.Text("Untap (f)", "bold 24px Arial", "black")
        button2.x = 870
        button2.y = 720
        button2.hitArea = new Shape(new Graphics().beginFill("rgba(255,0,0,100)").rect(0,0,200,50))
        button2.on("pressup", (evt) ->
                untapAll()
        )

        button3 = new createjs.Text("Draw (d)", "bold 24px Arial", "black")
        button3.x = 870
        button3.y = 670
        button3.hitArea = new Shape(new Graphics().beginFill("rgba(255,0,0,100)").rect(0,0,200,50))
        button3.on("pressup", (evt) ->
                drawCard()
        )
        
        table.addChild(button1)
        table.addChild(button2)
        table.addChild(button3)

        document.onkeydown = (evt) ->
                keycode = evt.keyCode
                if keycode == 68
                        drawCard()
                if keycode == 70
                        untapAll()
                if keycode == 83
                        showDeck()
        console.log("init finished")

        createjs.Ticker.addEventListener("tick", tick)
        createjs.Ticker.setFPS(60)

        $.get("token.txt").done((result) -> tokenList = result.trim().split("\n"))

tick = (event) ->
        stage.update(event)

window.addEventListener("load", ->
        container = document.getElementById("container")
        canvas = document.getElementById("canvas")
        ctx = canvas.getContext("2d")

        init(canvas)

        window.scrollBy(0, 1000)
, false)