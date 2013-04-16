
console.log("Summarize this shit")

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
	constructor: (participants, messages, first, last) ->
		@participants_ = participants
		@messages_ = []
		for i in [first..last]
			@messages_.push(messages[i])
	render: ->
		# Create the block element
		block = document.createElement('a')
		block.className = "fbNubButton"
		block.href = "#"
		block.innerHTML = @participants_.getAuthorsImgs()
		block.style.paddingLeft = "20px"
		block.style.paddingRight = "20px"
		block.style.height = "auto"
		block.innerHTML = block.innerHTML.concat(" x#{ @participants_.getNumMsgs() }")
		# Injects msgs into block
		msgContainer = document.createElement('div')
		msgContainer.className = "summaryMsgContainer"
		msgContainer.style.display = "none"
		#for msg in @messages_
		#	msgContainer.appendChild(msg)
		block.appendChild(msgContainer)
		# Insert the block
		parent = @messages_[0].parentElement
		parent.insertBefore(block, @messages_[0])
		# Remove msgs from chat
		#for msg in @messages_
		#	parent.removeChild(msg)
		return true

summarize = ->
	console.log "Inside summarize()"
	# Check for concurrent runs of this function
	if document.querySelector(".summarizationStamp") != null
		return false
	# Mark done
	stamp = document.createElement('div')
	stamp.className = "summarizationStamp"
	stamp.style.display = "none"
	document.querySelector("body").appendChild(stamp)
	# Load more messages
	document.querySelector("._2nc").querySelector(".uiScrollableAreaContent").scrollIntoView()
	msgsContainer = document.getElementById("webMessengerRecentMessages")
	if msgsContainer
		msgsContainer.addEventListener('DOMNodeInserted', (event)->
			messages = document.querySelectorAll("li.webMessengerMessageGroup")
			console.log "messages.length is #{messages.length}"
			if messages.length > 15 
				this.removeEventListener('DOMNodeInserted', arguments.callee, false)
			else
				return false
			console.log "Running summarize core"
			# Summarize it
			participants = new Participants()
			block_end = messages.length-1
			for i in [messages.length-1..0]
				console.log messages[i]
				msg = new Message(messages[i])
				console.log "parsing msg ##{ i } #{ msg.author() }: #{ msg.text() }"
				if participants.getNumAuthors() == 2 and not participants.hasAuthor(msg.author())
					console.log "detected a block starting at #{ i+1 } and finishing at #{ block_end }"
					block = new Block(participants, messages, i+1, block_end)
					block.render()
					participants = new Participants()
					block_end = i
				participants.register(msg)
			block = new Block(participants, messages, 0, block_end)
			block.render()
		,false)
	return true

tmout = setTimeout(->
	stamp = document.querySelector(".summarizationStamp")
	if stamp != null
		stamp.remove()
	return true
,1500)

summarize()
