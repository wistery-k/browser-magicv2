cardWidth = 81
cardHeight = 113

NO_INTERNET = false

imgPool = {}

getImage = (str) ->
        if str of imgPool
                return imgPool[str]
        img = new Image()
        img.src = str
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
// Deck file for Magic Workstation (http://www.magicworkstation.com)

// Lands
    1 [THS] Unknown Shores
    3 [THS] Plains (1)
    11 [THS] Forest (1)
    1 [THS] Nykthos, Shrine to Nyx

// Creatures
    1 [THS] Opaline Unicorn
    2 [THS] Staunch-Hearted Warrior
    1 [THS] Sylvan Caryatid
    2 [THS] Nylea's Disciple
    2 [THS] Voyaging Satyr
    2 [THS] Vulpine Goliath
    1 [THS] Centaur Battlemaster
    1 [THS] Chronicler of Heroes
    1 [THS] Fleecemane Lion
    1 [THS] Leafcrown Dryad
    2 [THS] Nessian Asp
    1 [THS] Nessian Courser

// Spells
    1 [THS] Time to Feed
    1 [THS] Savage Surge
    1 [THS] Traveler's Amulet
    1 [THS] Dauntless Onslaught
    1 [THS] Divine Verdict
    2 [THS] Feral Invocation

// Sideboard
SB: 1 [THS] Nylea's Presence
SB: 2 [THS] Shredding Winds
SB: 1 [THS] Fade into Antiquity
SB: 2 [THS] Commune with the Gods
SB: 1 [THS] Defend the Hearth
SB: 1 [THS] Hunt the Hunter
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
table = null

randomColor = ->
        r = ~~(Math.random() * 256)
        g = ~~(Math.random() * 256)
        b = ~~(Math.random() * 256)
        return "rgb(#{r},#{g},#{b})"

addCardToField = (bmp) ->
        bmp.on("pressup", (evt) ->
                if Math.sqrt(Math.pow(@dragStart.x - evt.stageX, 2) + Math.pow(@dragStart.y - evt.stageY, 2)) < 3
                        console.log(evt)
                        @rotation = (@rotation + 90) % 180
        )
        bmp.on("mousedown", (evt) ->
                @parent.addChild(@)
                @offset =
                        x: @x - evt.stageX
                        y: @y - evt.stageY
                @dragStart =
                        x: evt.stageX
                        y: evt.stageY
        )
        bmp.on("pressmove", (evt) ->
                @x = evt.stageX + @offset.x
                @y = evt.stageY + @offset.y
        )
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
                        new createjs.Shape(new createjs.Graphics().beginFill(randomColor()).rect(0, 0, cardWidth, cardHeight))

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
        
        box = new createjs.Shape(new createjs.Graphics().beginFill("rgb(188,188,188)").rect(0, 0, w, h))
        box.shadow = new createjs.Shadow("black", 5, 5, 10)
        layer.addChild(box)
        
        layer.addChild(new createjs.Shape(new createjs.Graphics().beginFill("rgb(128,128,128)").rect(0, 0, w, 30)))
        layer.addChild(new createjs.Shape(new createjs.Graphics().setStrokeStyle(6).beginStroke("rgb(64,64,64)").moveTo(w-20, 5).lineTo(w-5, 20)))
        layer.addChild(new createjs.Shape(new createjs.Graphics().setStrokeStyle(6).beginStroke("rgb(64,64,64)").moveTo(w-20, 20).lineTo(w-5, 5)))

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
                        if @x < 0 or @y < 0 or @x > w or @y > h
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

untapAll = ->
        for o in table.children
                o.rotation = 0 if o.rotation?

init = (canvas) ->
        if createjs.Touch.isSupported()
                alert("HOGE")

        deck = parseMWDeck(mwdeck)
        shuffle(deck)

        canvas.oncontextmenu = (e) =>
                e.preventDefault()
                return false

        stage = new createjs.Stage(canvas)
        createjs.Touch.enable(stage)

        table = new createjs.Container()
        stage.addChild(table)

        table.addChild(new createjs.Shape(new createjs.Graphics().beginFill("rgb(222,222,222)").rect(0, 0, canvas.width, canvas.height)))
        handBorder1 = new createjs.Shape(new createjs.Graphics().beginStroke("rgb(111,111,111)").moveTo(10, 140).lineTo(850, 140))
        handBorder1.shadow = new createjs.Shadow("black",1,5,5) 
        table.addChild(handBorder1)
        table.addChild(new createjs.Shape(new createjs.Graphics().beginStroke("rgb(111,111,111)").moveTo(10, 400).lineTo(850, 400)))
        handBorder2 = new createjs.Shape(new createjs.Graphics().beginStroke("rgb(111,111,111)").moveTo(10, 660).lineTo(850, 660))
        handBorder2.shadow = new createjs.Shadow("black",1,-5,5)
        table.addChild(handBorder2)
        table.addChild(new createjs.Shape(new createjs.Graphics().beginStroke("rgb(111,111,111)").moveTo(860, 10).lineTo(860, canvas.height - 10)))

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
        
        deckBmp.addEventListener("mousedown", (evt) ->
                console.log(evt)
                drawCard()
        )
        table.addChild(deckBmp)

        button1 = new createjs.Text("Search deck (s)", "bold 24px Arial", "black")
        button1.x = 870
        button1.y = 770
        button1.hitArea = new createjs.Shape(new createjs.Graphics().beginFill("rgba(255,0,0,100)").rect(0,0,200,50))
        button1.on("pressup", (evt) ->
                showDeck()
        )

        button2 = new createjs.Text("Untap (f)", "bold 24px Arial", "black")
        button2.x = 870
        button2.y = 720
        button2.hitArea = new createjs.Shape(new createjs.Graphics().beginFill("rgba(255,0,0,100)").rect(0,0,200,50))
        button2.on("pressup", (evt) ->
                untapAll()
        )

        button3 = new createjs.Text("Draw (d)", "bold 24px Arial", "black")
        button3.x = 870
        button3.y = 670
        button3.hitArea = new createjs.Shape(new createjs.Graphics().beginFill("rgba(255,0,0,100)").rect(0,0,200,50))
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

tick = (event) ->
        stage.update(event)

window.addEventListener("load", ->
        container = document.getElementById("container")
        canvas = document.getElementById("canvas")
        ctx = canvas.getContext("2d")

        init(canvas)

        if not ("first_time" of localStorage)
                alert("README: Ctrl+Shift+J")
                localStorage.setItem("first_time", "")
, false)