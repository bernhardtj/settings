import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Pango from 'gi://Pango';
import GLib from 'gi://GLib';

const TICKER_WIDTH = 400;
const SCROLL_SPEED_PX_PER_SECOND = 80;
const STATIC_MESSAGE_MS = 2500;
const MEASURE_RETRY_MS = 50;
const LONG_MESSAGE_LEAD_IN_MS = 900;
const LONG_MESSAGE_END_HOLD_MS = 900;

export default class TickerExtension extends Extension {
    enable() {
        this._timeouts = new Set();
        this._sourceSignals = new Map();
        this._handledNotifications = new WeakSet();
        this._currentNotification = null;
        this._currentNotificationDestroyId = 0;

        this._button = new St.Button({
            style_class: 'panel-button',
            reactive: true,
            can_focus: true,
            track_hover: true,
            y_align: Clutter.ActorAlign.CENTER,
        });

        this._button.connect('clicked', () => this._activateCurrentNotification());

        // Container for clipping so text remains inside ticker bounds
        this._container = new St.Widget({
            style_class: 'ticker-container',
            layout_manager: new Clutter.FixedLayout(),
            clip_to_allocation: true,
            width: TICKER_WIDTH,
            y_align: Clutter.ActorAlign.CENTER,
        });

        this._tickerLabel = new St.Label({
            style_class: 'ticker-label',
            y_align: Clutter.ActorAlign.CENTER,
            x_align: Clutter.ActorAlign.START,
            x_expand: false,
        });
        this._tickerLabel.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;
        this._tickerLabel.clutter_text.line_wrap = false;
        this._tickerLabel.clutter_text.single_line_mode = true;

        this._container.add_child(this._tickerLabel);
        this._button.set_child(this._container);
        Main.panel._rightBox.insert_child_at_index(this._button, 0);

        this._sourceAddedId = Main.messageTray.connect('source-added',
            (_tray, source) => this._connectSource(source));

        for (const source of Main.messageTray.getSources?.() ?? [])
            this._connectSource(source);
    }

    _connectSource(source) {
        if (!source || this._sourceSignals.has(source))
            return;

        const originalAddNotification = this._patchSourceAddNotification(source);
        const notificationAddedId = source.connect('notification-added',
            (_src, notification) => this._handleNotification(notification));
        const requestBannerId = source.connect('notification-request-banner',
            (_src, notification) => this._handleNotification(notification));

        const destroyId = source.connect('destroy', () => {
            const ids = this._sourceSignals.get(source);
            if (!ids)
                return;
            if (ids.originalAddNotification)
                source.addNotification = ids.originalAddNotification;
            if (ids.notificationAddedId)
                source.disconnect(ids.notificationAddedId);
            if (ids.requestBannerId)
                source.disconnect(ids.requestBannerId);
            if (ids.destroyId)
                source.disconnect(ids.destroyId);
            this._sourceSignals.delete(source);
        });

        this._sourceSignals.set(source, {
            originalAddNotification,
            notificationAddedId,
            requestBannerId,
            destroyId,
        });
    }

    _patchSourceAddNotification(source) {
        if (typeof source.addNotification !== 'function')
            return null;

        const originalAddNotification = source.addNotification;
        const extension = this;

        source.addNotification = function (notification) {
            extension._handleNotification(notification);
            return originalAddNotification.call(this, notification);
        };

        return originalAddNotification;
    }

    _handleNotification(notification) {
        if (!notification || this._handledNotifications.has(notification))
            return;

        this._handledNotifications.add(notification);

        const message = this._notificationMessage(notification);
        if (!message)
            return;

        this._suppressNativeBanner(notification);
        this._setCurrentNotification(notification);
        this._showTicker(message);
    }

    _notificationMessage(notification) {
        const summary = `${notification.title ?? notification.summary ?? ''}`.trim();
        const body = `${
            notification.bannerBodyText ??
            notification.body ??
            notification.bannerBody ??
            ''
        }`.trim();

        return `${summary ? `${summary}: ` : ''}${body}`.trim();
    }

    _suppressNativeBanner(notification) {
        if (!notification)
            return;

        try {
            notification.acknowledged = true;
        } catch (error) {
            logError(error, `${this.metadata.uuid}: failed to suppress native notification banner`);
        }
    }

    _setCurrentNotification(notification) {
        if (this._currentNotification && this._currentNotificationDestroyId) {
            try {
                this._currentNotification.disconnect(this._currentNotificationDestroyId);
            } catch (error) {
                logError(error, `${this.metadata.uuid}: failed to disconnect previous notification`);
            }
        }

        this._currentNotification = notification;
        this._currentNotificationDestroyId = notification.connect('destroy', () => {
            if (this._currentNotification === notification)
                this._currentNotification = null;

            if (this._currentNotificationDestroyId) {
                notification.disconnect(this._currentNotificationDestroyId);
                this._currentNotificationDestroyId = 0;
            }
        });
    }

    _showTicker(message) {
        this._clearTimeouts();
        this._tickerLabel.remove_all_transitions();

        this._tickerLabel.set_text(message.replace(/\s+/g, ' ').trim());
        this._tickerLabel.set_width(-1);
        this._tickerLabel.clutter_text.set_width(-1);
        this._tickerLabel.translation_x = 0;
        this._container.visible = true;
        this._button.visible = true;

        this._addTimeout(MEASURE_RETRY_MS, () => {
            const [, naturalWidth] = this._tickerLabel.clutter_text.get_preferred_width(-1);
            const containerWidth = this._container.get_width() || TICKER_WIDTH;

            if (naturalWidth <= 0 || containerWidth <= 0) {
                this._addTimeout(MEASURE_RETRY_MS, () => {
                    this._showTicker(message);
                    return GLib.SOURCE_REMOVE;
                });
                return GLib.SOURCE_REMOVE;
            }

            this._tickerLabel.set_width(naturalWidth);
            this._tickerLabel.clutter_text.set_width(naturalWidth);
            this._tickerLabel.translation_x = 0;

            if (naturalWidth <= containerWidth) {
                this._addTimeout(STATIC_MESSAGE_MS, () => {
                    this._hideTicker();
                    return GLib.SOURCE_REMOVE;
                });
                return GLib.SOURCE_REMOVE;
            }

            const endX = containerWidth - naturalWidth;
            const distancePx = naturalWidth - containerWidth;
            const duration = Math.max(
                1000,
                Math.round((distancePx / SCROLL_SPEED_PX_PER_SECOND) * 1000)
            );

            this._addTimeout(LONG_MESSAGE_LEAD_IN_MS, () => {
                this._tickerLabel.ease({
                    translation_x: endX,
                    duration,
                    mode: Clutter.AnimationMode.LINEAR,
                    onComplete: () => {
                        this._addTimeout(LONG_MESSAGE_END_HOLD_MS, () => {
                            this._hideTicker();
                            return GLib.SOURCE_REMOVE;
                        });
                    },
                });

                return GLib.SOURCE_REMOVE;
            });

            return GLib.SOURCE_REMOVE;
        });
    }

    _activateCurrentNotification() {
        if (!this._currentNotification)
            return;

        try {
            this._currentNotification.activate();
        } catch (error) {
            logError(error, `${this.metadata.uuid}: failed to activate notification`);
        }

        this._hideTicker();
    }

    _addTimeout(delayMs, callback) {
        const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, delayMs, () => {
            this._timeouts.delete(id);
            return callback();
        });
        this._timeouts.add(id);
        return id;
    }

    _clearTimeouts() {
        for (const id of this._timeouts)
            GLib.source_remove(id);
        this._timeouts.clear();
    }

    _hideTicker() {
        this._clearTimeouts();
        this._tickerLabel.remove_all_transitions();
        this._container.visible = false;
        this._tickerLabel.set_text("");
        this._tickerLabel.set_width(-1);
        this._tickerLabel.clutter_text.set_width(-1);
        this._tickerLabel.translation_x = 0;

        if (this._currentNotification && this._currentNotificationDestroyId) {
            try {
                this._currentNotification.disconnect(this._currentNotificationDestroyId);
            } catch (error) {
                logError(error, `${this.metadata.uuid}: failed to disconnect notification destroy handler`);
            }
        }

        this._currentNotificationDestroyId = 0;
        this._currentNotification = null;
    }

    disable() {
        this._clearTimeouts();

        if (this._sourceAddedId)
            Main.messageTray.disconnect(this._sourceAddedId);

        for (const [source, ids] of this._sourceSignals) {
            if (ids.originalAddNotification)
                source.addNotification = ids.originalAddNotification;
            if (ids.notificationAddedId)
                source.disconnect(ids.notificationAddedId);
            if (ids.requestBannerId)
                source.disconnect(ids.requestBannerId);
            if (ids.destroyId)
                source.disconnect(ids.destroyId);
        }
        this._sourceSignals.clear();

        this._button?.destroy();
        this._button = null;
        this._container = null;
        this._tickerLabel = null;
        this._handledNotifications = null;
        this._currentNotificationDestroyId = 0;
        this._currentNotification = null;
    }
}
