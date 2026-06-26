package components;

import haxe.ui.components.Label;
import haxe.ui.core.Screen;
import backend.utils.Update;
import backend.online.dma.DMAPostType;
import backend.online.dma.DMASortType;
import backend.online.dma.DMA;
import haxe.ui.core.ItemRenderer;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.containers.ListView;
import haxe.ui.containers.Frame;
import haxe.ui.components.TextField;
import haxe.ui.components.Spacer;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.VBox;
import haxe.ui.components.Button;

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/modbrowser.xml"))
class ModBrowser extends VBox {
    public var searchBar:TextField;
    public var searchButton:MenuItem;
    public var spacer:Spacer;
    public var switchButton:MenuItem;
    public var searchOptions:Menu;

    // DMA Specific
    public var sortTypes:ListView;
    public var postTypes:ListView;

    // false = DMA, true = GB
    public var currentType:Bool = false;

    public var currentPage:Int = 0;
    public var lastPageWasEmpty:Bool = false;
    public var pageLabel:Label;
    public var prevPageButton:Button;
    public var nextPageButton:Button;

    public function new() {
        super();
        genMenuBarContent();
        modGrid.autoHeight = true;
        modGridScrollView.horizontalScrollPolicy = 'never';
        Update.register(this, (_) -> {
            modGridFrame.height = (Screen.instance.height - modBrowserTopMenu.height - 50) * 0.95;
            modGridScrollView.componentWidth = modGridFrame.width;
            modGridScrollView.componentHeight = modGridFrame.height;
            modGridScrollView.width = modGridFrame.width;
            modGridScrollView.height = modGridFrame.height;
            modGridScrollView.contentWidth = modGridFrame.width;
            modGrid.componentWidth = modGridFrame.width;
            modGrid.width = modGridFrame.width;
        });
        haxe.Timer.delay(() -> {
            searchButton.disabled = false;
        }, 2000);
    }

    public function genMenuBarContent() {
        modBrowserTopMenu.removeAllComponents();

        searchOptions = new Menu();
        searchOptions.text = 'Options';
        searchOptions.verticalAlign = 'center';
        searchOptions.styleString = 'padding: 5px; spacing: 5px;';
        modBrowserTopMenu.addComponent(searchOptions);

        if (currentType) {
            // GB
        } else {
            var sortTypeFrame:Frame = new Frame();
            sortTypeFrame.text = 'Sort By';
            sortTypes = new ListView();
            sortTypes.dataSource = new ArrayDataSource<Dynamic>();
            sortTypes.dataSource.add({ text: 'Newest' });
            sortTypes.dataSource.add({ text: 'Oldest' });
            sortTypes.dataSource.add({ text: 'Most Downloaded' });
            sortTypes.dataSource.add({ text: 'Most Liked' });
            sortTypes.dataSource.add({ text: 'Least Downloaded' });
            sortTypes.dataSource.add({ text: 'Least Liked' });
            sortTypes.percentWidth = 100;
            sortTypes.selectedIndex = 0;
            sortTypeFrame.addComponent(sortTypes);
            searchOptions.addComponent(sortTypeFrame);

            var postTypeFrame:Frame = new Frame();
            postTypeFrame.text = 'Post Type';
            postTypes = new ListView();
            postTypes.itemRenderer = new PostTypeItemRenderer();
            postTypes.dataSource = new ArrayDataSource<Dynamic>();
            postTypes.dataSource.add({ enabled: true, label: 'Song' });
            postTypes.dataSource.add({ enabled: true, label: 'Cover' });
            postTypes.dataSource.add({ enabled: true, label: 'Module' });
            postTypes.dataSource.add({ enabled: true, label: 'UI' });
            postTypes.dataSource.add({ enabled: true, label: 'Plugin' });
            postTypes.dataSource.add({ enabled: true, label: 'Other' });
            postTypes.percentWidth = 100;
            postTypeFrame.addComponent(postTypes);
            searchOptions.addComponent(postTypeFrame);
        }

        searchBar = new TextField();
        searchBar.placeholder = 'Search here...';
        searchBar.text = '';
        searchBar.percentWidth = 50;
        searchBar.verticalAlign = 'center';
        modBrowserTopMenu.addComponent(searchBar);

        searchButton = new MenuItem();
        searchButton.icon = 'resources/icons/search.svg';
        searchButton.horizontalAlign = 'center';
        searchButton.disabled = true;
        searchButton.onClick = (_) -> {
            resetAndSearch();
        }
        modBrowserTopMenu.addComponent(searchButton);

        spacer = new Spacer();
        spacer.percentWidth = 50;
        modBrowserTopMenu.addComponent(spacer);

        switchButton = new MenuItem();
        switchButton.text = ((currentType) ? 'Switch to Diva Mod Archive' : 'Switch to GameBanana');
        switchButton.verticalAlign = 'center';
        switchButton.onClick = (_) -> {
            currentType = !currentType;
            genMenuBarContent();
            resetSearch();
        }
        modBrowserTopMenu.addComponent(switchButton);

        prevPageButton = new Button();
        prevPageButton.text = '< Prev';
        prevPageButton.verticalAlign = 'center';
        prevPageButton.disabled = true;
        prevPageButton.onClick = (_) -> {
            if (currentPage > 0) {
                currentPage--;
                search();
            }
        }
        modBrowserTopMenu.addComponent(prevPageButton);

        pageLabel = new Label();
        pageLabel.verticalAlign = 'center';
        pageLabel.text = 'Page 1';
        modBrowserTopMenu.addComponent(pageLabel);

        nextPageButton = new Button();
        nextPageButton.text = 'Next >';
        nextPageButton.verticalAlign = 'center';
        nextPageButton.disabled = true;
        nextPageButton.onClick = (_) -> {
            currentPage++;
            search();
        }
        modBrowserTopMenu.addComponent(nextPageButton);
    }

    public function resetSearch() {
        currentPage = 0;
        lastPageWasEmpty = false;
        modGrid.removeAllComponents();
    }

    public function resetAndSearch() {
        currentPage = 0;
        lastPageWasEmpty = false;
        search();
    }

    public function search() {
        modGrid.removeAllComponents();
        searchButton.disabled = true;

        var sort:DMASortType;
        switch ((sortTypes.selectedItem.text:String)) {
            case 'Newest': sort = DMASortType.Newest;
            case 'Oldest': sort = DMASortType.Oldest;
            case 'Most Downloaded': sort = DMASortType.MostDownloaded;
            case 'Most Liked': sort = DMASortType.MostLiked;
            case 'Least Downloaded': sort = DMASortType.LeastDownloaded;
            case 'Least Liked': sort = DMASortType.LeastLiked;
            default: sort = DMASortType.Newest;
        }

        var finalTypes:Array<DMAPostType> = [];
        var presentTypes:Array<Dynamic> = [];
        var enabledTypes:Array<Dynamic> = [];

        for (i in 0...postTypes.dataSource.size)
            presentTypes.push(postTypes.dataSource.get(i));

        for (type in presentTypes)
            if (type.enabled) enabledTypes.push(type.label);

        for (type in enabledTypes) {
            switch (type) {
                case 'Song': finalTypes.push(DMAPostType.Song);
                case 'Cover': finalTypes.push(DMAPostType.Cover);
                case 'Module': finalTypes.push(DMAPostType.Module);
                case 'UI': finalTypes.push(DMAPostType.UI);
                case 'Plugin': finalTypes.push(DMAPostType.Plugin);
                case 'Other': finalTypes.push(DMAPostType.Other);
                default: finalTypes.push(DMAPostType.Other);
            }
        }

        var data = DMA.getMods(searchBar.text, sort, finalTypes, currentPage * 30, 30);
        var thisPageEmpty = false;

        if (data.error != '') {
            trace(data.error);
            thisPageEmpty = true;
        } else {
            thisPageEmpty = data.mods.length == 0;
            for (modIdx in 0...data.mods.length) {
                var mod = data.mods[modIdx];
                modGrid.addComponent(new DMAModComponent(mod, modIdx));
            }
        }
    
        var nextData = DMA.getMods(searchBar.text, sort, finalTypes, (currentPage + 1) * 30, 30);
        var nextPageEmpty = (nextData.error != '') || nextData.mods.length == 0;

        nextPageButton.disabled = thisPageEmpty || nextPageEmpty;
        prevPageButton.disabled = currentPage == 0;

        lastPageWasEmpty = thisPageEmpty;
        pageLabel.text = 'Page ${currentPage + 1}';

        haxe.Timer.delay(() -> {
            modGridScrollView.invalidateComponentLayout();
            modGrid.invalidateComponentLayout();
            modGridScrollView.vscrollPos = 0;
            modGrid.height += 20;
            haxe.Timer.delay(() -> {
                searchButton.disabled = false;
            }, 1000);
        }, 25);

        if (thisPageEmpty && currentPage != 0)
            resetAndSearch();
    }
}

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/posttypeitemrenderer.xml"))
private class PostTypeItemRenderer extends ItemRenderer {
    public function new() {
        super();
    }
}