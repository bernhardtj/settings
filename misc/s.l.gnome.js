// .local/share/gnome-shell/extensions/settings@localhost/extension.js
let clockDisplay;
let dateTimeDisplay;
let updateTimeoutID;

function init() {
	clockDisplay = imports.ui.main.panel.statusArea.dateMenu._clockDisplay;
	dateTimeDisplay = new imports.gi.St.Label({
		y_align: imports.gi.Clutter.ActorAlign.CENTER
	});
}

// specify timezone backwards; ie: CDT=GMT+0500 rather than GMT-0500 as it actually is.
function convert(date, timezone) {
    return new Date((new Date(date.toUTCString().replace(/GMT.*$/g, timezone))).toUTCString().replace(/GMT.*$/g, ''))
}

function update() {
    const now = new Date()
    const cdt = convert(now, 'GMT+0600')
    const cet = convert(now, 'GMT-0100')

    dateTimeDisplay.set_text(
        now.toLocaleFormat('%a %b %d  ') +
	now.toLocaleFormat('%l˸%M %p  /  ') +
	    cet.toLocaleFormat('%H˸%M  /  ') +
	    cdt.toLocaleFormat('%l˸%M %p  /  ') +
	    (+now.toLocaleFormat('%s') + -315964782) // GPS time.
	    // Offset from unix time as of 9/19/19. Re-calibrate every ~18 months. 
    );
    return true;
}

function enable() {
    clockDisplay.hide();
    clockDisplay.get_parent().insert_child_below(dateTimeDisplay, clockDisplay);
    updateTimeoutID = imports.gi.GLib.timeout_add(
    	imports.gi.GLib.PRIORITY_DEFAULT, 1000, update
    );
}

function disable() {
    imports.gi.GLib.Source.remove(updateTimeoutID);
    updateTimeoutID = 0;
    clockDisplay.show();
    clockDisplay.get_parent().remove_child(dateTimeDisplay);
}
