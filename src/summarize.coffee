
class Message
	constructor: (element) ->
		@imgEl_ = element.querySelector('img._s0')
		@author_ = element.querySelector('._36 > a').innerHTML
		@text_ = ""
		for p in element.querySelectorAll("._38 > p")
			@text_ = @text_.concat(p.innerHTML).concat(" ")
	author: ->
		@author_
	text: ->
		@text_
	image: ->
		@imgEl_

Stamp = {} 
Stamp._className = "summarizationStamp5678"
Stamp.set = ->
	console.log "Added the Stamp"
	stamp = document.createElement('div')
	stamp.className = Stamp._className
	stamp.style.display = "none"
	document.querySelector("body").appendChild(stamp)
	return stamp
Stamp.isSet = ->
	return document.querySelector(".#{ Stamp._className }") != null
Stamp.waitAndUnset = ->
	tmout = setTimeout(->
		stamp = document.querySelector(".#{ Stamp._className }")
		if stamp != null
			console.log "Removed the Stamp"
			stamp.remove()
		return true
	,1500)
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
		keywords = {}
		for i in [first..last]
			@rawmessages_.push(rawmessages[i])
			msg = new Message(rawmessages[i])
			for word in msg.text().split(" ")
				word = word.replace(/(\.|\?|\!|\,|\:|\;|\'|\/|\\)/g,"")
				word = word.replace("(","").replace(")","")
				word = word.toLowerCase()
				if not(word in @badwords_) and word.search(/\w/) >= 0
					word = word.charAt(0).toUpperCase()+word.slice(1)
					if keywords[word] then keywords[word]+=1 else keywords[word] = 1
		@topkeywords_ = []
		`for(var key in keywords) {
			//if(keywords[key] === 1)
			//	delete keywords[key];
			//else
				this.topkeywords_.push([key, keywords[key]]);
		}`
		sortDesc = (array) ->
			return array.sort( (a, b) ->
				`((a[1] > b[1]) ? -1 : ((a[1] < b[1]) ? 1 : 0))`
			)
		@topkeywords_ = (item[0] for item in sortDesc(@topkeywords_)[0..5])
	badwords_: [
		"o","e","a","de","pra","do","da","para","que","q","eu","ele",
		"vc","vo","sem","no","na","esse","essa","este","esta","aquele","aquela",
		"prefiro","aqueles","aquelas","por","ta","acha","acho","dele","dela",
		"como","muito","muita","mto","mta","tem","tinha","é","achei","achou",
		"dos","das","tao","tão","com","sim","não","nao","n","s","sss","nnn",
		"ss","nn","uma","um","dois","duas","tipo","tambem","tbm","também","te",
		"até","nos","nas","tá","se","em","cada","minha","minhas","meu","meus",
		"desde","tmbm","mas","as","os","merda","isso","isto","mesmo","mesma",
		"bem","alguma","alguns","algum","sei","vai","dar","depois","antes","aqui"
	]
	render: ->
		# Create the block element
		block = document.createElement('a')
		block.className = "fbNubButton summarizedBlock"
		block.href = "#"
		block.innerHTML = @participants_.getAuthorsImgs()
		block.innerHTML = block.innerHTML.concat(" x#{ @participants_.getNumMsgs() }")
		keywords = document.createElement('span')
		keywords.className = "summaryKeywords"
		keywords.innerHTML = @topkeywords_.join(", ")
		block.appendChild(keywords)
		block.style.paddingLeft = "20px"
		block.style.paddingRight = "20px"
		block.style.height = "auto"
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
			packedMsgs = msgContainer.querySelectorAll('li')
			for rawmsg in packedMsgs
				e.target.parentNode.insertBefore(rawmsg, e.target)
			block.remove()
			e.stopPropagation()
			e.preventDefault()
		,false)
		return true

scrollToTopLoadMsgs = ->
	document.querySelector("._2nc").querySelector(".uiScrollableAreaContent").scrollIntoView()

scrollToBottomMessage = (messages) ->
	messages[messages.length-1].scrollIntoView()

streamLengthPattern = [12, 25, 52, 93, 132, 178, 210, 250, 296, 352, 399]
predictNextStreamLength = (currentStreamLength) ->
	for x in streamLengthPattern
		if x > currentStreamLength
			return x
	return streamLengthPattern[streamLengthPattern.length-1]

summarize = ->
	console.log "Inside summarize()"
	if Stamp.isSet()
		return false
	Stamp.set()
	# Load more messages
	predictedStreamLength = predictNextStreamLength(document.querySelectorAll("li.webMessengerMessageGroup").length)
	scrollToTopLoadMsgs()
	msgsContainer = document.getElementById("webMessengerRecentMessages")
	if msgsContainer
		msgsContainer.addEventListener('DOMNodeInserted', (event)->
			messages = document.querySelectorAll("li.webMessengerMessageGroup")
			#console.log "messages.length is #{messages.length}"
			if messages.length == predictedStreamLength-8
				this.removeEventListener('DOMNodeInserted', arguments.callee, false)
			else
				return false
			scrollToBottomMessage(messages)
			console.log "Running summarize core"
			# Summarize it
			participants = new Participants()
			block_end = messages.length-1
			for i in [messages.length-1..0]
				#console.log messages[i]
				msg = new Message(messages[i])
				#console.log "Parsing msg ##{ i } #{ msg.author() }: #{ msg.text() }"
				if participants.getNumAuthors() == 2 and not participants.hasAuthor(msg.author())
					#console.log "==> Detected a block starting at #{ i+1 } and finishing at #{ block_end }"
					block = new Block(participants, messages, i+1, block_end)
					block.render()
					participants = new Participants()
					block_end = i
				participants.register(msg)
			block = new Block(participants, messages, 0, block_end)
			block.render()
			Stamp.waitAndUnset()
		,false)
	return true

summarize()
