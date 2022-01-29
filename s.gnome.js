/* .local/share/gnome-shell/extensions/settings@localhost/extension.js
 * documentation can be found at:
 * - https://gjs-docs.gnome.org
 * - https://gitlab.gnome.org/GNOME/gnome-shell/-/tree/main/js/ui
 * logging utility: js function 'log()' and 'journalctl -f -o cat /usr/bin/gnome-shell'
 * global.window_manager is a Shell.WM object.
 */

const WS1 = imports.ui.workspace.WorkspaceBackground;
const WS2 = imports.gi.GObject.registerClass(class WorkspaceBackground2 extends imports.gi.St.Widget {
    _init(...args) {
        super._init({layout_manager: new imports.gi.Clutter.BinLayout()});
    }
});

let do_not_provision = false;

const Extension = imports.gi.GObject.registerClass(class Extension extends imports.gi.GObject.Object {
    get settings() {
        if (this._settings === undefined) this._settings = new imports.gi.Gio.Settings({
            settings_schema: imports.gi.Gio.SettingsSchemaSource.new_from_directory(
                imports.misc.extensionUtils.getCurrentExtension().dir.get_child('schemas').get_path(),
                imports.gi.Gio.SettingsSchemaSource.get_default(), false)
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
            const m = w.get_work_area_for_monitor(i < 2 * global.display.get_n_monitors() ? ~~(i / 2) : imports.ui.main.layoutManager.primaryIndex);
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
            imports.ui.main.wm.addKeybinding(name, this.settings, 0, imports.gi.Shell.ActionMode.NORMAL,
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
        imports.ui.workspace.WorkspaceBackground = WS2;
        this.overviewBackground = new imports.ui.background.BackgroundManager({
            monitorIndex: imports.ui.main.layoutManager.primaryIndex,
            container: imports.ui.main.layoutManager.overviewGroup,
        });
    }

    disable() {
        this.handles.forEach(h => global.window_manager.disconnect(h));
        ['flop-left', 'flop-right'].forEach(name => imports.ui.main.wm.removeKeybinding(name));
        this.overviewBackground.destroy();
        imports.ui.workspace.WorkspaceBackground = WS1;
    }
});

function init() {
    return new Extension();
}
