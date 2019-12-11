var Se_Meridium_ProcessMap_dom_e2 = Se_Meridium_ProcessMap_CheckDomCompabilityLevel('events', '2.0');
var Se_Meridium_ProcessMap_dom_c2 = Se_Meridium_ProcessMap_CheckDomCompabilityLevel('core', '2.0');
var Se_Meridium_ProcessMap_mouseX;
var Se_Meridium_ProcessMap_mouseY;
var Se_Meridium_ProcessMap_currentOpenLayer = null;
var Se_Meridium_ProcessMap_currentHoover = null;

if (Se_Meridium_ProcessMap_dom_e2) {
    if (window.addEventListener) {
        window.addEventListener('mousemove', Se_Meridium_ProcessMap_MouseMove, false);
        window.addEventListener('mouseup', Se_Meridium_ProcessMap_MouseUp, true);
    } else if (document.addEventListener) {
        document.addEventListener('mousemove', Se_Meridium_ProcessMap_MouseMove, false);
        document.addEventListener('mouseup', Se_Meridium_ProcessMap_MouseUp, true);
    }
} else {
    document.onmousemove = Se_Meridium_ProcessMap_MouseMove;
    document.onmouseup = Se_Meridium_ProcessMap_MouseUp;
}

function Se_Meridium_ProcessMap_CheckDomCompabilityLevel(a, b) {
    return (document && document.implementation && document.implementation.hasFeature && document.implementation.hasFeature(a, b));
}

function Se_Meridium_ProcessMap_MouseMove(e) {
    e = e || window.event;
    Se_Meridium_ProcessMap_mouseX = e.clientX || e.x;
    Se_Meridium_ProcessMap_mouseY = e.clientY || e.y;
}

function Se_Meridium_ProcessMap_MouseUp(e) {
    e = e || window.event;
    var src = e.srcElement || e.target;
    var button = e.button || e.which;
    if (button != 2) {
        if (Se_Meridium_ProcessMap_currentOpenLayer != null) {
            //did we click inside the current layer?
            while (src != null && src != Se_Meridium_ProcessMap_currentOpenLayer) {
                src = src.parentNode;
            }
            if (src == null) {
                Se_Meridium_ProcessMap_HideMenu();
            }
        }
    }
    return false;
}

function Se_Meridium_ProcessMap_HideMenu() {
    if (Se_Meridium_ProcessMap_currentOpenLayer != null) {
        //new popup menu
        if (IsNewPopup(Se_Meridium_ProcessMap_currentOpenLayer)) {
            Se_Meridium_ProcessMap_currentOpenLayer.className = "pmLinkPopupHidden";
        } else {
            //old popup menu
            Se_Meridium_ProcessMap_currentOpenLayer.className = "pmLinkListHidden";
            HoverBGOut(Se_Meridium_ProcessMap_currentHoover);
        }
        Se_Meridium_ProcessMap_currentOpenLayer = null;
    }
}
function IsNewPopup(layer) {
    return (layer.className == "pmLinkPopupHidden" || layer.className == "pmLinkPopup");
}
function OpenLayer(layer) {
    var isNewPopup = IsNewPopup(layer);
    var id = "Se_Meridium_ProcessMap_pmb" + layer.id
    var popup = document.getElementById(id);
    if (popup == null) {
        popup = document.createElement("div");
        popup.setAttribute("id", id);
        document.body.appendChild(popup);
    }
    popup.innerHTML = layer.innerHTML; // Always load fresh data to the menu

    var left, top;
    if (document && document.all && document.all.tags && document.all.tags("HTML")) {
        left = document.all.tags("HTML")(0).scrollLeft;
        top = document.all.tags("HTML")(0).scrollTop;
    } else {
        left = document.documentElement.scrollLeft;
        top = document.documentElement.scrollTop;
    }

    //new popup menu
    if (isNewPopup) {
        popup.className = "pmLinkPopup";
    } else {
        //old popup menu
        popup.className = "pmLinkList";
    }
    popup.style.left = (Se_Meridium_ProcessMap_mouseX + document.body.scrollLeft + left) + "px";
    popup.style.top = (Se_Meridium_ProcessMap_mouseY + document.body.scrollTop + top) + "px";

    Se_Meridium_ProcessMap_currentOpenLayer = popup;
}

function OpenLayerById(layerId) {
    var layer = document.getElementById(layerId);
    return OpenLayer(layer);
}

function OpenSingleLink(str, target) {
    if (str != null && str != "") {
        if (target == '_blank')
            window.open(str, '_blank');
        else if (target == '_top') {
            window.open(str, '_top');
        } else {
            window.location = str;
        }
    }
}

function OpenExternalLink(str, target) {
	if (str != null && str != "") {
		str = '/Plugins/Processmap/ExternalLink?fileuri=' + encodeURIComponent(str);
		if (target == '_blank')
			window.open(str, '_blank');
		else if (target == '_top') {
			window.open(str, '_top');
		} else {
			window.location = str;
		}
	}
}

function HoverBG(that) {
    if (Se_Meridium_ProcessMap_currentHoover != null) {
        HoverBGOut(Se_Meridium_ProcessMap_currentHoover);
    }
    if (that && that.style) {
        Se_Meridium_ProcessMap_currentHoover = that;
        that.className = "pmLinkListRowHover";
    }
}

function HoverBGOut(that) {
    if (that && that.style) {
        that.className = "pmLinkListRow";
        if (Se_Meridium_ProcessMap_currentHoover == that) {
            Se_Meridium_ProcessMap_currentHoover = null;
        }
    }
}