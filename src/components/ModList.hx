package components;

import haxe.ui.events.UIEvent;

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/modlist.xml"))
class ModList extends DraggableTableView {
    public function new() {
        super();
    }

    public function resetFilter() {
        modNameFilter.text = '';
    }

    @:bind(modNameFilter, UIEvent.CHANGE)
    function onModNameFilterChange(_) {
        if (modNameFilter.text == null || modNameFilter.text == '') {
            dataSource.clearFilter();
        } else {
            dataSource.filter(function(index, data) {
                return fuzzyContainsAllChars(data.colName, modNameFilter.text);
            });
        }
    }

    function fuzzyContainsAllChars(target:String, query:String):Bool {
        var t = target.toLowerCase();
        var q = query.toLowerCase();
        for (i in 0...q.length)
            if (t.indexOf(q.charAt(i)) == -1) return false;
        return true;
    }
}