/* .local/share/gnome-shell/extensions/settings-main@localhost/extension.js
 * documentation can be found at:
 * - https://gjs-docs.gnome.org
 * - https://gitlab.gnome.org/GNOME/gnome-shell/-/tree/main/js/ui
 * logging utility: js function 'log()' and 'journalctl -f -o cat /usr/bin/gnome-shell'
 * global.window_manager is a Shell.WM object.
 */

import Cairo from 'cairo';
import System from 'system';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Workspace from 'resource:///org/gnome/shell/ui/workspace.js';
import * as Background from 'resource:///org/gnome/shell/ui/background.js';
import * as Util from 'resource:///org/gnome/shell/misc/util.js';
import * as extensionUtils from 'resource:///org/gnome/shell/misc/extensionUtils.js';

import Adw from 'gi://Adw';
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk?version=4.0';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk?version=4.0';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import St from 'gi://St';

const WS1 = Workspace.WorkspaceBackground;
const WS2 = class WorkspaceBackground2 extends St.Widget {
    _init(...args) {
        super._init({layout_manager: new Clutter.BinLayout()});
    }
}

let do_not_provision = false;

export default class TheExtension extends Extension {
    get settings() {
        if (this._settings === undefined) this._settings = new Gio.Settings({
            settings_schema: Gio.SettingsSchemaSource.new_from_directory(
		this.path.concat('/schemas'),
                Gio.SettingsSchemaSource.get_default(), false)
                .lookup('org.gnome.shell.extensions.settings', true)
        });
        return this._settings;
    }

    get window_order() {
        if (this._window_order === undefined) this._window_order = [];
        return this._window_order;
    }

    set window_order(value) {
        if (this.window_order === value) return;
        this._window_order = value;
    }

    provision() {
        if (do_not_provision) return;
        do_not_provision = true;
        this.window_order = this.window_order.filter((w, i) => w || i % 2);
        for (const [i, w] of this.window_order.entries()) {
            if (!w) continue;
            w.change_workspace_by_index(i < 2 * global.display.get_n_monitors() ? 0 : ~~(i / 2) - global.display.get_n_monitors() + 1, true);
            const m = w.get_work_area_for_monitor(i < 2 * global.display.get_n_monitors() ? ~~(i / 2) : Main.layoutManager.primaryIndex);
            w.move_resize_frame(true, m.x + 10 + (i % 2) * ~~(m.width / 2), m.y + 10,
                ~~(m.width / (1 + (this.window_order[i + 1] && (this.window_order.length - 1 !== i) || (i % 2)))) - 20, m.height - 20);
        }
        do_not_provision = false;
    }

    enable() {
        this.handles = ['map', 'unminimize'].map(signal =>
            global.window_manager.connect(signal, (_, actor) => {
                if (actor.meta_window.get_maximized()) actor.meta_window.unmaximize(actor.meta_window.get_maximized());
                if (actor.meta_window.allows_move() && actor.meta_window.allows_resize() && !actor.meta_window.window_type) {
                    let idx = actor.meta_window.get_workspace().index();
                    idx += ((idx > 0) || (actor.meta_window.get_monitor() > 0)) ? global.display.get_n_monitors() - 1 : 0;
                    if (this.window_order.length < 2 * idx)
                        this.window_order = this.window_order.concat(new Array(2 * idx - this.window_order.length).fill(null));
                    this.window_order = this.window_order
                        .slice(0, 2 * idx + 1).concat(actor.meta_window).concat(this.window_order.slice(2 * idx + 1));
                }
                this.provision();
            })).concat(['destroy', 'minimize'].map(signal =>
            global.window_manager.connect(signal, (_, actor) => {
                this.window_order = this.window_order.map(w => w !== actor.meta_window ? w : null);
                this.provision();
            }))).concat(['filter-keybinding', 'hide-tile-preview', 'size-changed', 'switch-workspace'].map(signal =>
            global.window_manager.connect(signal, () => this.provision())));
        ['flop-left', 'flop-right'].forEach((name, direction) =>
            Main.wm.addKeybinding(name, this.settings, 0, Shell.ActionMode.NORMAL,
                () => {
                    const w = global.display.get_focus_window();
                    const i = this.window_order.indexOf(w);
                    const intention = i + (2 * direction - 1) * (1 + !this.window_order[i + 2 * direction - 1]);
                    if ((intention >= 0) && (intention < this.window_order.length)) {
                        this.window_order[i] = this.window_order[intention];
                        this.window_order[intention] = w;
                    }
                    this.provision();
                }));
        //Workspace.workspaceBackground = WS2;
        this.overviewBackground = new Background.BackgroundManager({
            monitorIndex: Main.layoutManager.primaryIndex,
            container: Main.layoutManager.overviewGroup,
        });
    }

    disable() {
        this.handles.forEach(h => global.window_manager.disconnect(h));
        ['flop-left', 'flop-right'].forEach(name => Main.wm.removeKeybinding(name));
        this.overviewBackground.destroy();
	//Workspace.WorkspaceBackground = WS1;
    }
}
