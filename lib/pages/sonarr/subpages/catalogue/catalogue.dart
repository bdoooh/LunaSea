import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lunasea/logic/automation/sonarr.dart';
import 'package:lunasea/pages/sonarr/subpages/details/edit.dart';
import 'package:lunasea/pages/sonarr/subpages/details/show.dart';
import 'package:lunasea/system/constants.dart';
import 'package:lunasea/system/ui.dart';

class Catalogue extends StatelessWidget {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

    Catalogue({
        Key key,
        @required this.refreshIndicatorKey,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return _CatalogueWidget(refreshIndicatorKey: refreshIndicatorKey);
    }
}

class _CatalogueWidget extends StatefulWidget {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

    _CatalogueWidget({
        Key key,
        @required this.refreshIndicatorKey,
    }) : super(key: key);

    @override
    State<StatefulWidget> createState() {
        return _CatalogueState(refreshIndicatorKey: refreshIndicatorKey);
    }
}

class _CatalogueState extends State<StatefulWidget> {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    final _searchController = TextEditingController();
    String searchFilter = '';
    bool _loading = true;
    bool _hideUnmonitored = false;

    List<SonarrCatalogueEntry> _catalogueEntries = [];
    List<SonarrCatalogueEntry> _searchedEntries = [];

    _CatalogueState({
        Key key,
        @required this.refreshIndicatorKey,
    });

    @override
    void initState() {
        super.initState();
        _searchController.addListener(() {
            setState(() {
                searchFilter = _searchController.text;
                _searchedEntries = _catalogueEntries.where(
                    (entry) => searchFilter == 'null' || searchFilter == '' ? entry != null : entry.title.toLowerCase().contains(searchFilter.toLowerCase()),
                ).toList();
            });
        });
        Future.delayed(Duration(milliseconds: 200)).then((_) {
            if(mounted) {
                refreshIndicatorKey?.currentState?.show();
            } 
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            floatingActionButton: _buildFloatingActionButton(),
            body: RefreshIndicator(
                key: refreshIndicatorKey,
                backgroundColor: Color(Constants.SECONDARY_COLOR),
                onRefresh: _handleRefresh,
                child: _loading ? 
                    Notifications.centeredMessage('Loading...') :
                    _catalogueEntries == null ? 
                        Notifications.centeredMessage('Connection Error', showBtn: true, btnMessage: 'Refresh', onTapHandler: () {refreshIndicatorKey?.currentState?.show();}) : 
                        _catalogueEntries.length == 0 ? 
                            Notifications.centeredMessage('No Series Found', showBtn: true, btnMessage: 'Refresh', onTapHandler: () {refreshIndicatorKey?.currentState?.show();}) :
                            _buildList(),
            ),
        );
    }

    Widget _buildFloatingActionButton() {
        if(_loading || _catalogueEntries == null) {
            return Container();
        }
        return FloatingActionButton(
            heroTag: null,
            child: Elements.getIcon(_hideUnmonitored ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Hide/Unhide Unmonitored Series',
            onPressed: () {
                setState(() {
                    _hideUnmonitored = !_hideUnmonitored;
                });
            },
        );
    }

    Future<void> _handleRefresh() async {
        if(mounted) {
            setState(() {
                _loading = true;
                _catalogueEntries = [];
                _searchedEntries = [];
                _hideUnmonitored = false;
            });
        }
        _catalogueEntries = await SonarrAPI.getAllSeries();
        if(_catalogueEntries != null && _catalogueEntries.length != 0) {
            _catalogueEntries.sort((a,b) => a.sortTitle.compareTo(b.sortTitle));
            _searchedEntries = _catalogueEntries;
            _searchController.text = '';
        }
        if(mounted) {
            setState(() {
                _loading = false;
            });
        }
    }

    Widget _noEntries(String message) {
        return Card(
            child: ListTile(
                title: Text(
                    message,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                    ),
                ),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Widget _buildList() {
        bool monitored = false;
        if(_hideUnmonitored) {
            for(var entry in _searchedEntries) {
                if(entry.monitored) {
                    monitored = true;
                    break;
                }
            }
        }
        return Scrollbar(
            child: ListView.builder(
                itemCount: (_searchedEntries.length == 0 || (_hideUnmonitored && !monitored)) ? 2 : _searchedEntries.length+1,
                itemBuilder: (context, index) {
                    if((_searchedEntries.length == 0 || (_hideUnmonitored && !monitored))) {
                        return index == 0 ? _buildSearch() : _noEntries(_hideUnmonitored ? 'No Monitored Series Found' : 'No Series Found');
                    }
                    return index == 0 ? _buildSearch() : _buildEntry(_searchedEntries[index-1], index-1);
                },
                padding: Elements.getListViewPadding(),
                physics: AlwaysScrollableScrollPhysics(),
            ),
        );
    }

    Widget _buildSearch() {
        return Card(
            child: Padding(
                child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                        labelText: 'Search Series...',
                        labelStyle: TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.none,
                        ),
                        icon: Padding(
                            child: Icon(
                                Icons.search,
                                color: Color(Constants.ACCENT_COLOR),
                            ),
                            padding: EdgeInsets.fromLTRB(20.0, 8.0, 0.0, 8.0),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    style: TextStyle(
                        color: Colors.white,
                    ),
                    cursorColor: Color(Constants.ACCENT_COLOR),
                ),
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Widget _buildEntry(SonarrCatalogueEntry entry, int index) {
        if(_hideUnmonitored && !entry.monitored) {
            return Container();
        }
        return Card(
            child: Container(
                child: ListTile(
                    title: Elements.getTitle(entry.title, darken: !entry.monitored),
                    subtitle: Elements.getSubtitle(entry.subtitle, darken: !entry.monitored, preventOverflow: true, maxLines: 2),
                    trailing: IconButton(
                        alignment: Alignment.center,
                        icon: Elements.getIcon(
                            entry.monitored ? Icons.turned_in : Icons.turned_in_not,
                            color: entry.monitored ? Colors.white : Colors.white30,
                        ),
                        tooltip: 'Toggle Monitored',
                        onPressed: () async {
                            if(await SonarrAPI.toggleSeriesMonitored(entry.seriesID, !entry.monitored)) {
                                setState(() {
                                    entry.monitored = !entry.monitored;
                                });
                                Notifications.showSnackBar(
                                    _scaffoldKey,
                                    entry.monitored ? 'Monitoring ${entry.title}' : 'No longer monitoring ${entry.title}',
                                );
                                _refreshSingleEntry(entry, index);
                            } else {
                                Notifications.showSnackBar(
                                    _scaffoldKey,
                                    entry.monitored ? 'Failed to stop monitoring ${entry.title}' : 'Failed to start monitoring ${entry.title}',
                                );
                            }
                        },
                    ),
                    onTap: () async {
                        _enterShow(entry, index);
                    },
                    onLongPress: () async {
                        List<dynamic> values = await SonarrDialogs.showEditSeriesPrompt(context, entry);
                        if(values[0]) {
                            switch(values[1]) {
                                case 'refresh_series': {
                                    if(await SonarrAPI.refreshSeries(entry.seriesID)) {
                                        Notifications.showSnackBar(_scaffoldKey, 'Refreshing ${entry.title}...');
                                    } else {
                                        Notifications.showSnackBar(_scaffoldKey, 'Failed to refresh ${entry.title}');
                                    }
                                    break;
                                }
                                case 'edit_series': {
                                    await _enterEditSeries(entry);
                                    break;
                                }
                                case 'remove_series': {
                                    values = await SonarrDialogs.showDeleteSeriesPrompt(context);
                                    if(values[0]) {
                                        if(await SonarrAPI.removeSeries(entry.seriesID)) {
                                            Notifications.showSnackBar(_scaffoldKey, 'Removed ${entry.title}');
                                            refreshIndicatorKey?.currentState?.show();
                                        } else {
                                            Notifications.showSnackBar(_scaffoldKey, 'Failed to remove ${entry.title}');
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    },
                    contentPadding: Elements.getContentPadding(),
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AdvancedNetworkImage(
                            entry.bannerURI(),
                            useDiskCache: true,
                            loadFailedCallback: () {},
                            fallbackAssetImage: 'assets/images/secondary_color.png',
                            retryLimit: 1,
                        ),
                        colorFilter: new ColorFilter.mode(Color(Constants.SECONDARY_COLOR).withOpacity(entry.monitored ? 0.20 : 0.10), BlendMode.dstATop),
                        fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Future<void> _enterShow(SonarrCatalogueEntry entry, int index) async {
        final result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => SonarrShowDetails(entry: entry),
            ),
        );
        //Handle the result
        switch(result) {
            case 'series_deleted': {
                Notifications.showSnackBar(_scaffoldKey, 'Removed ${entry.title}');
                refreshIndicatorKey?.currentState?.show();
                break;
            }
            default: {
                _refreshSingleEntry(entry, index);
                break;
            }
        }
    }

    Future<void> _enterEditSeries(SonarrCatalogueEntry entry) async {
        final result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => SonarrEditSeries(entry: entry),
            ),
        );
        //Handle the result
        if(result != null) {
            switch(result[0]) {
                case 'updated_series': {
                    setState(() {
                       entry = result[1]; 
                    });
                    Notifications.showSnackBar(_scaffoldKey, 'Updated ${entry.title}');
                    break;
                }
            }
        }
    }

    Future<void> _refreshSingleEntry(SonarrCatalogueEntry entry, int index) async {
        SonarrCatalogueEntry _entry = await SonarrAPI.getSeries(entry.seriesID);
        _entry ??= _searchedEntries[index];
        if(mounted) {
            if(_searchedEntries[index]?.title == entry.title) {
                setState(() {
                    _searchedEntries[index] = _entry;
                });
            }
        }
    }
}
