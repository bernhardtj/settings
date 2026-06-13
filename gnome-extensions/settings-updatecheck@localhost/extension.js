import GObject from "gi://GObject";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import * as Main from "resource:///org/gnome/shell/ui/main.js";
import * as QuickSettings from "resource:///org/gnome/shell/ui/quickSettings.js";
import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";

// Time to wait after login before checking (5 minutes)
const CHECK_DELAY_SECONDS = 300;

const UpdateIndicator = GObject.registerClass(
class UpdateIndicator extends QuickSettings.SystemIndicator {
    _init() {
        super._init();

        this._indicator = this._addIndicator();
        this._indicator.icon_name = "software-update-available-symbolic";
        
        // Default to hidden; only show if we find a staged update later
        this._indicator.visible = false; 

        this._timeoutId = null;
        
        // Schedule the single check
        this._startOneOffTimer();
    }

    _startOneOffTimer() {
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, 
            CHECK_DELAY_SECONDS, 
            () => {
                this._checkRpmOstreeAsync();
                this._timeoutId = null;
                return GLib.SOURCE_REMOVE; // Ensures it runs only once
            }
        );
    }

    _checkRpmOstreeAsync() {
        try {
            // Create the subprocess asynchronously
            let proc = new Gio.Subprocess({
                argv: ['rpm-ostree', 'status', '--json'],
                flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
            });
            
            proc.init(null);

            // Run the command and wait for output without blocking the main thread
            proc.communicate_utf8_async(null, null, (proc, res) => {
                try {
                    let [, stdout, stderr] = proc.communicate_utf8_finish(res);

                    if (!proc.get_successful()) {
                        console.error(`rpm-ostree status failed: ${stderr}`);
                        return;
                    }

                    this._parseStatus(stdout);

                } catch (e) {
                    console.error(`Error reading rpm-ostree output: ${e}`);
                }
            });
        } catch (e) {
            console.error(`Failed to launch rpm-ostree subprocess: ${e}`);
        }
    }

    _parseStatus(jsonString) {
        try {
            const data = JSON.parse(jsonString);

            // Look for any deployment marked as 'staged'
            let isStaged = false;
            if (data && data.deployments) {
                isStaged = data.deployments.some(d => d.staged);
            }

            // Update UI on main thread (callbacks usually run on main, but safe to be sure)
            this._indicator.visible = isStaged;

        } catch (e) {
            console.error(`Error parsing rpm-ostree JSON: ${e}`);
        }
    }

    destroy() {
        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = null;
        }
        super.destroy();
    }
});

export default class UpdateExtension extends Extension {
    enable() {
        this._indicator = new UpdateIndicator();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
        this._moveIndicator();
    }

    _moveIndicator() {
        // Optional: Move indicator to the start of the row
        const quickSettings = Main.panel.statusArea.quickSettings;
        const indicators = quickSettings._indicators;
        const firstChild = indicators.get_children()[0];
        if (firstChild) {
            indicators.set_child_below_sibling(this._indicator, firstChild);
        }
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
