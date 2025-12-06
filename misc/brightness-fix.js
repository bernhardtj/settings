import GObject from "gi://GObject";
import Gio from "gi://Gio";
import Clutter from "gi://Clutter";
import GLib from "gi://GLib";
import * as Main from "resource:///org/gnome/shell/ui/main.js";
import * as QuickSettings from "resource:///org/gnome/shell/ui/quickSettings.js";
import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";
import { OsdWindow } from "resource:///org/gnome/shell/ui/osdWindow.js";

// Global step size for brightness adjustments
const BRIGHTNESS_STEP = 7;

function _runLightCommand(args) {
    try {
        let [ok, out, err, status] = GLib.spawn_command_line_sync(args);
        if (!ok || status !== 0) {
            logError(new Error(`light command failed: ${err}`));
            return null;
        }
        return out.toString().trim();
    } catch (e) {
        logError(e);
        return null;
    }
}

function getBrightness() {
    let out = _runLightCommand("light -G");
    if (out === null) return null;
    return Math.round(parseFloat(out));
}

function increaseBrightness() {
    _runLightCommand(`light -A ${BRIGHTNESS_STEP}`);
}

function decreaseBrightness() {
    _runLightCommand(`light -U ${BRIGHTNESS_STEP}`);
}

const BrightnessIndicator = GObject.registerClass(
class BrightnessIndicator extends QuickSettings.SystemIndicator {
    _init() {
        super._init();

        this._indicator = this._addIndicator();
        this._indicator.icon_name = "display-brightness-symbolic";
        this._indicator.visible = true;
        this._indicator.reactive = true;

        this._osdWindow = null;
        this._osdTimeoutId = null;

        this._scrollId = this._indicator.connect(
            "scroll-event",
            this._onScroll.bind(this)
        );
    }

    _showBrightnessOSD(brightness) {
        if (this._osdTimeoutId) {
            GLib.source_remove(this._osdTimeoutId);
            this._osdTimeoutId = null;
        }

        if (!this._osdWindow) {
            const monitorIndex = Main.layoutManager.focusMonitor.index || 0;
            this._osdWindow = new OsdWindow(monitorIndex);

            const icon = Gio.icon_new_for_string("display-brightness-symbolic");

            this._osdWindow.setIcon(icon);
            this._osdWindow.setLevel(brightness / 100);
            this._osdWindow.setLabel(`${brightness}%`);

            this._osdWindow.show();
        } else {
            this._osdWindow.setLevel(brightness / 100);
            this._osdWindow.setLabel(`${brightness}%`);
            this._osdWindow.show();
        }

        this._osdTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1500, () => {
            this._hideBrightnessOSD();
            this._osdTimeoutId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _hideBrightnessOSD() {
        if (this._osdTimeoutId) {
            GLib.source_remove(this._osdTimeoutId);
            this._osdTimeoutId = null;
        }

        if (this._osdWindow) {
            this._osdWindow.cancel();
            this._osdWindow = null;
        }
    }

    _onScroll(actor, event) {
        const direction = event.get_scroll_direction();

        if (direction === Clutter.ScrollDirection.UP) {
            increaseBrightness();
        } else if (direction === Clutter.ScrollDirection.DOWN) {
            decreaseBrightness();
        } else {
            return Clutter.EVENT_PROPAGATE;
        }

        const currentBrightness = getBrightness();
        if (currentBrightness !== null) {
            this._showBrightnessOSD(currentBrightness);
        }

        return Clutter.EVENT_STOP;
    }

    destroy() {
        this._hideBrightnessOSD();

        if (this._scrollId) {
            this._indicator.disconnect(this._scrollId);
            this._scrollId = null;
        }
        super.destroy();
    }
});

export default class BrightnessExtension extends Extension {
    enable() {
        this._indicator = new BrightnessIndicator();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
        this._moveAfterVolume();
    }

    _moveAfterVolume() {
        const quickSettings = Main.panel.statusArea.quickSettings;
        const indicators = quickSettings._indicators;

        let volumeIndicator = null;
        for (let indicator of indicators.get_children()) {
            const children = indicator.get_children();
            for (let child of children) {
                if (child.icon_name && child.icon_name.includes("audio-volume")) {
                    volumeIndicator = indicator;
                    break;
                }
            }
            if (volumeIndicator) break;
        }

        if (volumeIndicator) {
            indicators.set_child_above_sibling(this._indicator, volumeIndicator);
        }
    }

    disable() {
        if (this._indicator) {
            this._indicator._hideBrightnessOSD();
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}

