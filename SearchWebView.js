//
//  SearchWebView.js
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

// Based on this tutorial: http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

// We're using a global variable to store the number of occurrences
var Simplicity_SearchResultCount = 0;

// helper function, recursively searches in elements and their child nodes
function Simplicity_HighlightAllOccurencesOfStringForElement(element,keyword) {
	if (element) {
		if (element.nodeType == 3) {        // Text node
			while (true) {
				var value = element.nodeValue;  // Search for keyword in text node
				var idx = value.toLowerCase().indexOf(keyword);
				
				if (idx < 0) break;             // not found, abort
				
				var span = document.createElement("span");
				var text = document.createTextNode(value.substr(idx,keyword.length));
				span.appendChild(text);
				span.setAttribute("class", "Simplicity_Highlight");
				span.style.backgroundColor="yellow";
				span.style.color="black";
				text = document.createTextNode(value.substr(idx+keyword.length));
				element.deleteData(idx, value.length - idx);
				var next = element.nextSibling;
				element.parentNode.insertBefore(span, next);
				element.parentNode.insertBefore(text, next);
				element = text;
				Simplicity_SearchResultCount++;	// update the counter
			}
		} else if (element.nodeType == 1) { // Element node
			if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
				for (var i=element.childNodes.length-1; i>=0; i--) {
					Simplicity_HighlightAllOccurencesOfStringForElement(element.childNodes[i],keyword);
				}
			}
		}
	}
}

// the main entry point to start the search
function Simplicity_HighlightAllOccurencesOfString(keyword) {
	Simplicity_RemoveAllHighlights();
	Simplicity_HighlightAllOccurencesOfStringForElement(document.body, keyword.toLowerCase());
}

// helper function, recursively removes the highlights in elements and their childs
function Simplicity_RemoveAllHighlightsForElement(element) {
	if (element) {
		if (element.nodeType == 1) {
			if (element.getAttribute("class") == "Simplicity_Highlight") {
				var text = element.removeChild(element.firstChild);
				element.parentNode.insertBefore(text,element);
				element.parentNode.removeChild(element);
				return true;
			} else {
				var normalize = false;
				for (var i=element.childNodes.length-1; i>=0; i--) {
					if (Simplicity_RemoveAllHighlightsForElement(element.childNodes[i])) {
						normalize = true;
					}
				}
				if (normalize) {
					element.normalize();
				}
			}
		}
	}
	return false;
}

// the main entry point to remove the highlights
function Simplicity_RemoveAllHighlights() {
	Simplicity_SearchResultCount = 0;
	Simplicity_RemoveAllHighlightsForElement(document.body);
}
