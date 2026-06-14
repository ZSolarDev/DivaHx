package backend.utils;

import haxe.ui.core.Component;
import openfl.events.Event;
import openfl.Lib;

class Update {
    static var callbacks:Map<Component, Float->Void> = new Map();
    static var nonCCallbacks:Array<Float->Void> = [];
    static var lastTime:Float = 0;
    static var initialized:Bool = false;

    static function init() {
        if (initialized) return;
        initialized = true;
        lastTime = haxe.Timer.stamp();
        Lib.current.stage.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    public static function register(component:Component, update:Float->Void) {
        init();
        callbacks.set(component, update);
    }

    public static function unregister(component:Component) {
        callbacks.remove(component);
    }

    public static function registerNonC(update:Float->Void) {
        init();
        nonCCallbacks.push(update);
    }

    public static function unregisterNonC(update:Float->Void) {
        nonCCallbacks.remove(update);
    }

    static function onFrame(e:Event) {
        var now = haxe.Timer.stamp();
        var dt = now - lastTime;
        lastTime = now;

        for (update in callbacks) update(dt);
        for (update in nonCCallbacks) update(dt);
    }
}