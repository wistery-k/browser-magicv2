cardWidth = 81
cardHeight = 118

NO_INTERNET = true

imgPool = {}

getImage = (str) ->
        if str of imgPool
                return imgPool[str]
        img = new Image()
        img.src = str
        imgPool[str] = img
        return img

getCardImage = (card) ->
        return getImage("http://gatherer.wizards.com/Handlers/Image.ashx?type=card&name=" + encodeURI(card))

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
                cardName = ""
                for i in [2..(st.length-1)]
                        if st[i][0] == "("
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

drawCard = ->
        if deck.length == 0
                alert("library out!!!")
                return
        card = deck.pop()
        console.log(card)

        cardDrawX = 170
        for elem in table.children
                if elem.y > 460 and elem.x + cardWidth + 10 > cardDrawX
                        cardDrawX = elem.x + cardWidth + 10
        
        bmp =
                if !NO_INTERNET
                        img = getCardImage(card)
                        bmp = new createjs.Bitmap(img)
                        bmp.scaleX = cardWidth / img.width #
                        bmp.scaleY = cardHeight / img.Height #
                        bmp
                else
                        new createjs.Shape(new createjs.Graphics().beginFill(randomColor()).rect(0, 0, cardWidth, cardHeight))

        bmp.regX = cardWidth / 2 #
        bmp.regY = cardHeight / 2 #
        bmp.x = cardDrawX #+ bmp.regX
        bmp.y = 470 + bmp.regY
        
        bmp.on("click", (evt) ->
                evt.stopPropagation()
                if evt.nativeEvent.button == 0 && Math.sqrt(Math.pow(@dragStart.x - evt.stageX, 2) + Math.pow(@dragStart.y - evt.stageY, 2)) < 3
                        console.log(evt)
                        @rotation = (@rotation + 90) % 180
        )
        bmp.on(click(), (evt) ->
                if evt.nativeEvent.button == 0
                        console.log(evt)
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

showDeck = ->
        margin = 80
        padding = 30
        w = canvas.width - margin * 2
        h = canvas.height - margin * 2
        layer = new CanvasW.UIObject.Group(margin, margin)
        box = new CanvasW.UIObject.Rect("rgb(188,188,188)", 0, 0, w, h)
        box.shadow = true
        layer.addChild(box)
        layer.addChild(new CanvasW.UIObject.Rect("rgb(128,128,128)", 0, 0, w, 30))

        row = ~~((w - padding - cardWidth) / cardWidth) #
        num_row = ~~(deck.length / row) #
        step = ~~((h - padding * 2 - cardHeight) / num_row) #
        for card, i in deck
                x = padding + ~~(i / num_row) * cardWidth #
                y = padding * 2 + step * (i % num_row)
                layer.addChild(new CanvasW.UIObject.Image(getCardImage(card), x, y, cardWidth, cardHeight, 0))
        CanvasW.addChild(layer)

untapAll = ->
        for o in stage.children
                o.rotation = 0 if o.rotation?

click = ->
        if createjs.Touch.isSupported()
                "press"
        else
                "click"

init = (canvas) ->
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
        table.addChild(new createjs.Shape(new createjs.Graphics().beginStroke("rgb(111,111,111)", 0, 460, canvas.width)))

        deckImg =
                if !NO_INTERNET
                        img = getCardImage("null")
                        bmp = new createjs.Bitmap(img)
                        bmp.x = 10
                        bmp.y = 470
                        bmp.scaleX = cardWidth / img.width #
                        bmp.scaleY = cardHeight / img.Height #
                        bmp
                else
                        new createjs.Shape(new createjs.Graphics().beginFill("red").rect(10, 470, cardWidth, cardHeight))
        
        deckImg.addEventListener(click(), (evt) ->
                console.log(evt)
                drawCard()
        )
        table.addChild(deckImg)

        document.onkeydown = (evt) ->
                keycode = evt.keycode
                if keycode == 68
                        drawCard()
                if keycode == 70
                        untapAll()
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