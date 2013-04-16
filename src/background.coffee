chrome.tabs.onUpdated.addListener( (tabId, changeInfo, tab)->
	if tab.url.match("https://www.facebook.com/messages/*")
		chrome.pageAction.show(tab.id)
		console.log(chrome.pageAction.onClicked)
		chrome.pageAction.onClicked.addListener( (tab) ->
			chrome.tabs.executeScript(tab.id, {file: "/build/summarize.js"} )
		)
)
