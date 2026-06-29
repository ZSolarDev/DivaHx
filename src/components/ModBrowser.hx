package components;

import hl.Gc;
import backend.online.gamebanana.GB;
import backend.online.gamebanana.GBCategory;
import backend.online.gamebanana.GBSortType;
import haxe.ui.Toolkit;
import backend.online.dma.DMAModListResult;
import sys.thread.Thread;
import backend.utils.Validate;
import haxe.ui.components.Spinner;
import components.dialogs.ScrollDialog;
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
    public var searchBar:TextField = null;
    public var searchButton:MenuItem = null;
    public var spacer:Spacer = null;
    public var switchButton:MenuItem = null;
    public var searchOptions:Menu = null;

    public var sortTypes:ListView = null;
    public var postTypes:ListView = null;

    // false = DMA, true = GB
    public var currentType:Bool = false;

    public var currentPage:Int = 0;
    public var lastPageWasEmpty:Bool = false;
    public var pageLabel:Label = null;
    public var prevPageButton:Button = null;
    public var nextPageButton:Button = null;

    var oldHidden:Bool = true;
    var triggered:Bool = false;
    var isSearching:Bool = false;
    var startedValid:Bool = false;
    var preTrigger:Bool = false;
    public function new() {
        startedValid = Validate.isValidMMPath();
        super();
        genMenuBarContent(true);
        hidden = true;
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
            if (oldHidden != hidden && !hidden && !triggered && Validate.isValidMMPath()) {
                if (!startedValid) {
                    if (preTrigger) {
                        triggered = true;
                        resetAndSearch();
                    } else {
                        preTrigger = true;
                        hidden = true;
                    }
                } else {
                    triggered = true;
                    resetAndSearch();
                }
            }
            oldHidden = hidden;
        });
    }

    public function genMenuBarContent(?forceRegenOptions:Bool = false) {
        if (modBrowserTopMenu.contains(searchBar)) modBrowserTopMenu.removeComponent(searchBar, false);
        if (modBrowserTopMenu.contains(searchOptions)) modBrowserTopMenu.removeComponent(searchOptions, false);
        modBrowserTopMenu.removeAllComponents();

        if (searchOptions == null || forceRegenOptions) {
            searchOptions = new Menu();
            searchOptions.text = 'Options';
            searchOptions.verticalAlign = 'center';
            searchOptions.styleString = 'padding: 5px; spacing: 5px;';

            if (currentType) { // GameBanana
                var sortTypeFrame:Frame = new Frame();
                sortTypeFrame.text = 'Sort By';
                sortTypes = new ListView();
                sortTypes.dataSource = new ArrayDataSource<Dynamic>();
                sortTypes.dataSource.add({ text: 'Newest' });
                sortTypes.dataSource.add({ text: 'Oldest' });
                sortTypes.dataSource.add({ text: 'Latest Modified' });
                sortTypes.dataSource.add({ text: 'New and Updated' });
                sortTypes.dataSource.add({ text: 'Latest Updated' });
                sortTypes.dataSource.add({ text: 'Most Liked' });
                sortTypes.dataSource.add({ text: 'Most Commented' });
                sortTypes.dataSource.add({ text: 'Latest Comment' });
                sortTypes.dataSource.add({ text: 'Most Downloaded' });
                sortTypes.percentWidth = 100;
                sortTypes.selectedIndex = 0;
                sortTypeFrame.addComponent(sortTypes);
                searchOptions.addComponent(sortTypeFrame);

                var category:Frame = new Frame();
                category.text = 'Category';
                postTypes = new ListView();
                postTypes.dataSource = new ArrayDataSource<Dynamic>();
                postTypes.dataSource.add({ text: 'None' });
                postTypes.dataSource.add({ text: 'Covers' });
                postTypes.dataSource.add({ text: 'Custom Songs' });
                postTypes.dataSource.add({ text: 'Customization' });
                postTypes.dataSource.add({ text: 'Patches' });
                postTypes.dataSource.add({ text: 'Restorations & Fixes' });
                postTypes.dataSource.add({ text: 'User Interface' });
                postTypes.percentWidth = 100;
                postTypes.selectedIndex = 0;
                category.addComponent(postTypes);
                searchOptions.addComponent(category);
            } else { // Diva Mod Archive
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
                postTypes.itemRenderer = new DMAPostTypeItemRenderer();
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
        }

        modBrowserTopMenu.addComponent(searchOptions);

        if (searchBar == null || forceRegenOptions) {
            searchBar = new TextField();
            searchBar.placeholder = 'Search here...';
            searchBar.text = '';
            searchBar.percentWidth = 50;
            searchBar.verticalAlign = 'center';
        }
        modBrowserTopMenu.addComponent(searchBar);

        searchButton = new MenuItem();
        searchButton.icon = 'resources/icons/search.svg';
        searchButton.horizontalAlign = 'center';
        searchButton.disabled = isSearching;
        searchButton.onClick = (_) -> {
            resetAndSearch();
        }
        modBrowserTopMenu.addComponent(searchButton);

        if (isSearching) {
            var spinner:Spinner = new Spinner();
            spinner.styleString = 'filter: tint(#F6871F, 1)';
            spinner.width = 16;
            spinner.height = 16;
            spinner.verticalAlign = 'center';
            modBrowserTopMenu.addComponent(spinner);
        }

        spacer = new Spacer();
        spacer.percentWidth = 50;
        modBrowserTopMenu.addComponent(spacer);

        switchButton = new MenuItem();
        switchButton.text = ((currentType) ? 'Switch to Diva Mod Archive' : 'Switch to GameBanana (WIP)');
        switchButton.disabled = true;
        switchButton.verticalAlign = 'center';
        switchButton.onClick = (_) -> {
            currentType = !currentType;
            genMenuBarContent(true);
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
        if (isSearching) return;
        MainView.instance.mainTabs.disabled = true;
        isSearching = true;
        genMenuBarContent();

        modGrid.walkComponents((c) -> {
            if (Std.isOfType(c, DMAModComponent)) {
                var mod:DMAModComponent = cast c;
                mod.preDispose();
            }
            return true; 
        });
        modGrid.removeAllComponents(true);

        if (currentType) {
            var sort:GBSortType;
            switch ((sortTypes.selectedItem.text:String)) {
                case 'Newest': sort = GBSortType.Newest;
                case 'Oldest': sort = GBSortType.Oldest;
                case 'Latest Modified': sort = GBSortType.LatestModified;
                case 'New and Updated': sort = GBSortType.NewAndUpdated;
                case 'Latest Updated': sort = GBSortType.LatestUpdated;
                case 'Most Liked': sort = GBSortType.MostLiked;
                case 'Most Commented': sort = GBSortType.MostCommented;
                case 'Latest Comment': sort = GBSortType.LatestComment;
                case 'Most Downloaded': sort = GBSortType.MostDownloaded;
                default: sort = GBSortType.Newest;
            }

            var category:GBCategory;
            switch ((postTypes.selectedItem.text:String)) {
                case 'None': category = GBCategory.None;
                case 'Covers': category = GBCategory.Covers;
                case 'Custom Songs': category = GBCategory.CustomSongs;
                case 'Customization': category = GBCategory.Customization;
                case 'Patches': category = GBCategory.Patches;
                case 'Restorations & Fixes': category = GBCategory.RestorationsAndFixes;
                case 'User Interface': category = GBCategory.UI;
                default: category = GBCategory.None;
            }

            Thread.create(() -> {
                var data = GB.getMods(searchBar.text, category, sort, currentPage, 30);
                Toolkit.callLater(() -> {
                    onSearchData(data, sort, category);
                });
            });
        } else {
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

            Thread.create(() -> {
                var data = DMA.getMods(searchBar.text, sort, finalTypes, currentPage * 30, 30);
                Toolkit.callLater(() -> {
                    onSearchData(data, sort, finalTypes);
                });
            });
        }
    }

    public function onSearchData(data:Dynamic, sort:Dynamic, types:Dynamic) {
        var thisPageEmpty = false;

        if (data.error != '') {
            var dialog = new ScrollDialog('Failed to search mods!', '##### Failed to search mods!\nError: ${data.error}}', true);
            dialog.showDialog();
            thisPageEmpty = true;
            genMenuBarContent();
        } else {
            thisPageEmpty = data.mods.length == 0;
            for (modIdx in 0...data.mods.length) {
                var mod:Dynamic = data.mods[modIdx];
                if (currentType) 
                    modGrid.addComponent(new GBModComponent(mod, modIdx));
                else
                    modGrid.addComponent(new DMAModComponent(mod, modIdx));
            }
        }

        if (currentType) {
            Thread.create(() -> {
                var nextData = GB.getMods(searchBar.text, types, sort, currentPage + 1, 30);
                Toolkit.callLater(() -> {
                    onNextPageSearchData(nextData, thisPageEmpty);
                });
            });
        } else {
            Thread.create(() -> {
                var nextData = DMA.getMods(searchBar.text, sort, types, (currentPage + 1) * 30, 30);
                Toolkit.callLater(() -> {
                    onNextPageSearchData(nextData, thisPageEmpty);
                });
            });
        }
    }

    public function onNextPageSearchData(data:Dynamic, thisPageEmpty:Bool = false) {
        var nextPageEmpty = (data.error != '') || data.mods.length == 0;

        isSearching = false;
        MainView.instance.mainTabs.disabled = false;
        if (searchBar != null) searchBar.disabled = false;
        genMenuBarContent();

        nextPageButton.disabled = thisPageEmpty || nextPageEmpty;
        prevPageButton.disabled = currentPage == 0;

        lastPageWasEmpty = thisPageEmpty;
        pageLabel.text = 'Page ${currentPage + 1}';

        haxe.Timer.delay(() -> {
            modGridScrollView.invalidateComponentLayout();
            modGrid.invalidateComponentLayout();
            modGridScrollView.vscrollPos = 0;
            modGrid.height += 20;
        }, 25);

        if (thisPageEmpty && currentPage != 0)
            resetAndSearch();
        else {
            haxe.Timer.delay(() -> {
                Gc.major();
            }, 5000);
        }
    }
}

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/dmaposttypeitemrenderer.xml"))
private class DMAPostTypeItemRenderer extends ItemRenderer {
    public function new() {
        super();
    }
}