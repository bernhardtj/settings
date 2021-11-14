/* .local/share/gnome-shell/extensions/settings@localhost/extension.js
 * documentation can be found at https://gjs-docs.gnome.org.
 * global.window_manager is a Shell.WM object.
 */

const WS1 = imports.ui.workspace.WorkspaceBackground;
const WS2 = imports.gi.GObject.registerClass(class WorkspaceBackground2 extends imports.gi.St.Widget {
    _init(...args) {
        super._init({layout_manager: new imports.gi.Clutter.BinLayout()});
    }
});

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
        this.window_order = this.window_order.filter((w, i) => w || i % 2);
        for (const [i, w] of this.window_order.entries()) {
            if (!w) continue;
            w.change_workspace_by_index(~~(i / 2), true);
            const m = w.get_work_area_current_monitor();
            w.move_resize_frame(true, m.x + 10 + (i % 2) * ~~(m.width / 2), m.y + 10,
                ~~(m.width / (1 + (this.window_order[i + 1] && (this.window_order.length - 1 !== i) || (i % 2)))) - 20, m.height - 20);
        }
    }

    enable() {
        this._handles = [
            global.window_manager.connect('map', (_, actor) => {
                if (actor.meta_window.get_maximized()) actor.meta_window.unmaximize(actor.meta_window.get_maximized());
                if (actor.meta_window.allows_move() && actor.meta_window.allows_resize() && !actor.meta_window.window_type) {
                    if (this.window_order.length < 2 * actor.meta_window.get_workspace().index())
                        this.window_order = this.window_order.concat(new Array(
                            2 * actor.meta_window.get_workspace().index() - this.window_order.length).fill(null));
                    this.window_order = this.window_order
                        .slice(0, 2 * actor.meta_window.get_workspace().index() + 1)
                        .concat(actor.meta_window)
                        .concat(this.window_order.slice(2 * actor.meta_window.get_workspace().index() + 1));
                }
                this.provision();
            }),
            global.window_manager.connect('destroy', (_, actor) => {
                this.window_order = this.window_order.filter(w => w !== actor.meta_window);
                this.provision();
            })];
        ['filter-keybinding', 'hide-tile-preview', 'minimize', 'size-changed', 'switch-workspace', 'unminimize']
            .forEach(signal => this._handles.push(global.window_manager.connect(signal, () => this.provision())));
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
        this._overviewBackground = new imports.ui.background.BackgroundManager({
            monitorIndex: imports.ui.main.layoutManager.primaryIndex,
            container: imports.ui.main.layoutManager.overviewGroup,
        });
    }

    disable() {
        this._handles.forEach(h => global.window_manager.disconnect(h));
        ['flop-left', 'flop-right'].forEach(name => imports.ui.main.wm.removeKeybinding(name));
        this._overviewBackground.destroy();
        imports.ui.workspace.WorkspaceBackground = WS1;
    }
});

function init() {
    return new Extension();
}
