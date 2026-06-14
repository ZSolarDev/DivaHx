package components;

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/modlist.xml"))
class ModList extends DraggableTableView {
    public function new() {
        super();
    }
}