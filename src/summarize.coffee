
class Message
	constructor: (element) ->
		@imgEl_ = element.querySelector('img._s0')
		@author_ = element.querySelector('._36 > a').innerText
		@text_ = ""
		for p in element.querySelectorAll("._38 > p")
			@text_ = @text_.concat(p.innerText).concat(" ")
	author: ->
		@author_
	text: ->
		@text_
	image: ->
		@imgEl_


Stamp = {}
Stamp._className = "summarizationStamp5678"
Stamp.set = ->
	stamp = document.createElement('div')
	stamp.className = Stamp._className
	stamp.style.display = "none"
	document.querySelector("body").appendChild(stamp)
	return stamp
Stamp.isSet = ->
	return document.querySelector(".#{ Stamp._className }") != null
Stamp.waitAndUnset = (milisec) ->
	tmout = setTimeout(->
		stamp = document.querySelector(".#{ Stamp._className }")
		if stamp != null
			stamp.remove()
		return true
	,milisec)
	return tmout


class Participants
	constructor: ->
		@authorMsgCount_ = {}
		@authorImgs_ = {}
		@numAuthors_ = 0
		@numMsgs_ = 0
	getNumAuthors: ->
		@numAuthors_
	getNumMsgs: ->
		@numMsgs_
	hasAuthor: (authorName) ->
		return `this.authorMsgCount_[authorName] !== undefined`
	register: (msg) ->
		if @authorImgs_[msg.author()] is undefined
			@authorImgs_[msg.author()] = msg.image()
			@numAuthors_ += 1
		if @authorMsgCount_[msg.author()] is undefined
			@authorMsgCount_[msg.author()] = 1
		else
			@authorMsgCount_[msg.author()] += 1
		@numMsgs_ += 1
		return true
	getAuthorsImgs: ->
		imgsStr = ""
		imgsObj = @authorImgs_
		`for(var key in imgsObj) {
			imgsStr = imgsStr.concat(imgsObj[key].outerHTML);
			imgsStr = imgsStr.concat("&nbsp;");
		}`
		return imgsStr


class Block
	constructor: (participants, rawmessages, first, last) ->
		@participants_ = participants
		@rawmessages_ = []
		@keywords_ = {}
		for i in [first..last]
			@rawmessages_.push(rawmessages[i])
			msg = new Message(rawmessages[i])
			for word in msg.text().split(" ")
				word = word.replace(/(\.|\?|\!|\,|\:|\;|\'|\/|\\)/g,"")
				word = word.replace("(","").replace(")","")
				word = word.toLowerCase()
				if not(word in @badwords_) and word.search(/\w/) >= 0
					word = word.charAt(0).toUpperCase()+word.slice(1)
					if @keywords_[word] then @keywords_[word]+=1 else @keywords_[word] = 1
	getRawMessages: ->
		@rawmessages_
	getKeywords: ->
		@keywords_
	badwords_: [
		"o","e","a","de","pra","do","da","para","que","q","eu","ele",
		"vc","vo","sem","no","na","esse","essa","este","esta","aquele","aquela",
		"prefiro","aqueles","aquelas","por","ta","acha","acho","dele","dela",
		"como","muito","muita","mto","mta","tem","tinha","é","achei","achou",
		"dos","das","tao","tão","com","sim","não","nao","n","s","sss","nnn",
		"ss","nn","uma","um","dois","duas","tipo","tambem","tbm","também","te",
		"até","nos","nas","tá","se","em","cada","minha","minhas","meu","meus",
		"desde","tmbm","mas","as","os","merda","isso","isto","mesmo","mesma",
		"bem","alguma","alguns","algum","sei","vai","dar","depois","antes","aqui",
		"to","só","so","estou","você","voce","ja","já","pro","mais","tudo","faz",
		"porque","mim"
	]
	merge: (block_above) ->
		# Merge messages
		@rawmessages_ = block_above.getRawMessages().concat(@rawmessages_)
		# Merge participants
		for rawmsg in block_above.getRawMessages()
			msg = new Message(rawmsg)
			@participants_.register(msg)
		# Merge keywords
		`for(var word in block_above.getKeywords()) {
			if(this.keywords_[word]) {
				this.keywords_[word] += 1;	
			} else {
				this.keywords_[word] = 1;
			}
		}`
		return true
	render: ->
		# Create the block element
		block = document.createElement('a')
		block.className = "fbNubButton summarizedBlock"
		block.href = "#"
		block.innerHTML = @participants_.getAuthorsImgs()
		block.innerHTML = block.innerHTML.concat(" x#{ @participants_.getNumMsgs() }")
		# Process keywords
		topkeywords = []
		`for(var word in this.keywords_) {
			//if(keywords[word] === 1)
			//	delete keywords[word];
			//else
				topkeywords.push([word, this.keywords_[word]]);
		}`
		sortDesc = (array) ->
			return array.sort( (a, b) ->
				`((a[1] > b[1]) ? -1 : ((a[1] < b[1]) ? 1 : 0))`
			)
		topkeywords = (item[0] for item in sortDesc(topkeywords)[0..5])
		keywords = document.createElement('span')
		keywords.className = "summaryKeywords"
		keywords.innerHTML = topkeywords.join(", ")
		block.appendChild(keywords)
		# Injects msgs into block
		msgContainer = document.createElement('ul')
		msgContainer.className = "summaryMsgContainer"
		msgContainer.style.display = "none"
		block.appendChild(msgContainer)
		for rawmsg in @rawmessages_
			msgContainer.appendChild(rawmsg.cloneNode(true))
		# Insert the block
		parent = @rawmessages_[0].parentElement
		parent.insertBefore(block, @rawmessages_[0])
		# Remove msgs from chat
		for rawmsg in @rawmessages_
			parent.removeChild(rawmsg)
		# Click handler
		block.addEventListener("click", (e) -> 
			if e.target.className == "summaryKeywords"
				block = e.target.parentElement
			else
				block = e.target
			packedMsgs = msgContainer.querySelectorAll('li')
			turnOffListener()		
			for rawmsg in packedMsgs
				block.parentNode.insertBefore(rawmsg, block)
			block.remove()
			turnOnListener()
			e.stopPropagation()
			e.preventDefault()
		,false)
		return true


summarize = (messages) ->
	console.log "Inside summarize()"
	participants = new Participants()
	blocks = []
	block_end = messages.length-1
	for i in [messages.length-1..0]
		#console.log messages[i]
		msg = new Message(messages[i])
		#console.log "Parsing msg ##{ i } #{ msg.author() }: #{ msg.text() }"
		if participants.getNumAuthors() == 2 and not participants.hasAuthor(msg.author())
			#console.log "==> Detected a block starting at #{ i+1 } and finishing at #{ block_end }"
			block = new Block(participants, messages, i+1, block_end)
			if participants.getNumMsgs() < 6 and blocks.length > 0
				#console.log "----> Merging this block with the block below"
				blocks[0].merge(block)
			else
				blocks.unshift(block)
			# Start a new block
			participants = new Participants()
			block_end = i
		participants.register(msg)
	blocks.unshift( new Block(participants, messages, 0, block_end) )
	for block in blocks
		block.render()


scrollToTopLoadMsgs = ->
	document.querySelector("._2nc").querySelector(".uiScrollableAreaContent").scrollIntoView()


scrollToBottomMessage = (messages) ->
	messages[messages.length-1].scrollIntoView()


triggerSummarizeTimeout = null

turnOnListener = ->
	document.getElementById("webMessengerRecentMessages").addEventListener('DOMNodeInserted', insertedListener, false)

turnOffListener = ->
	document.getElementById("webMessengerRecentMessages").removeEventListener('DOMNodeInserted', insertedListener, false)

insertedListener = (event) ->
	console.log("DOM Node inserted")
	clearTimeout(triggerSummarizeTimeout)
	triggerSummarizeTimeout = setTimeout( ->
		turnOffListener()
		nodelist = document.querySelectorAll("li.webMessengerMessageGroup")
		messages = []
		for m in nodelist
			messages.push(m)
		scrollToBottomMessage(messages)
		#console.log "Will summarize in total #{ messages.length-7 } msgs"
		summarize( messages.splice(0,messages.length-7) )
		spacer = document.createElement('div')
		spacer.className = 'summarizationSpacer'
		spacer.innerHTML = '<div class="summarizationSpacerMore">&uarr; &uarr; &uarr;</div>'
		msgsContainer = document.getElementById("webMessengerRecentMessages")
		msgsContainer.insertBefore(spacer, msgsContainer.firstChild)
		Stamp.waitAndUnset(1500)
		turnOnListener()
	,613)
	return true

run = ->
	#console.log "Inside run()"
	if Stamp.isSet()
		return false
	Stamp.set()
	messages = document.querySelectorAll("li.webMessengerMessageGroup")
	#console.log "Initially: #{ messages.length } messages"
	if messages.length > 100
		summarize(messages)
	else # Load more messages
		scrollToTopLoadMsgs()
		msgsContainer = document.getElementById("webMessengerRecentMessages")
		if msgsContainer
			msgsContainer.addEventListener('DOMNodeInserted', insertedListener,false)
	return true


run()

