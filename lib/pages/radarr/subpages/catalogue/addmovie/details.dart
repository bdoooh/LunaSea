import 'package:flutter/material.dart';
import 'package:lunasea/logic/automation/radarr.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lunasea/system/constants.dart';
import 'package:lunasea/system/functions.dart';
import 'package:lunasea/system/ui.dart';

class RadarrMovieSearchDetails extends StatelessWidget {
    final RadarrSearchEntry entry;
    RadarrMovieSearchDetails({Key key, @required this.entry}): super(key: key);

    @override
    Widget build(BuildContext context) {
        return _RadarrMovieSearchDetailsWidget(entry: entry);
    }
}

class _RadarrMovieSearchDetailsWidget extends StatefulWidget {
    final RadarrSearchEntry entry;
    _RadarrMovieSearchDetailsWidget({Key key, @required this.entry}): super(key: key);

    @override
    State<StatefulWidget> createState() {
        return _RadarrMovieSearchDetailsState(entry: entry);
    }  
}

class _RadarrMovieSearchDetailsState extends State<StatefulWidget> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    final RadarrSearchEntry entry;

    List<RadarrQualityProfile> _qualityProfiles = [];
    List<RadarrRootFolder> _rootFolders = [];
    RadarrQualityProfile _qualityProfile;
    RadarrRootFolder _rootFolder;
    RadarrAvailabilityEntry _minimumAvailability;
    bool loading = true;
    bool monitored = true;

    _RadarrMovieSearchDetailsState({Key key, @required this.entry});

    @override
    void initState() {
        super.initState();
        _fetchData();
    }

    Future<void> _fetchData() async {
        if(mounted) {
            setState(() {
                loading = true;
            });
        }
        final profiles = await RadarrAPI.getQualityProfiles();
        _qualityProfiles = profiles?.values?.toList();
        if(_qualityProfiles != null && _qualityProfiles.length != 0) {
            _qualityProfile = _qualityProfiles[0];
        }
        _rootFolders = await RadarrAPI.getRootFolders();
        if(_rootFolders != null && _rootFolders.length != 0) {
            _rootFolder = _rootFolders[0];
        }
        _minimumAvailability = Constants.radarrMinAvailability[0];
        if(mounted) {
            setState(() {
                loading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(),
            body: loading ? 
                Notifications.centeredMessage('Loading...') : 
                _qualityProfile == null || _rootFolder == null ?
                    Notifications.centeredMessage('Connection Error', showBtn: true, btnMessage: 'Refresh', onTapHandler: () async {_fetchData();}) :
                    _buildList(),
            floatingActionButton: loading ?
                null :
                _qualityProfile == null || _rootFolder == null ?
                    null :
                    _buildFloatingActionButton(),
        );
    }

    Widget _buildFloatingActionButton() {
        return FloatingActionButton(
            heroTag: null,
            tooltip: 'Add Movie',
            child: Elements.getIcon(Icons.add),
            onPressed: () async {
                if(await RadarrAPI.addMovie(entry, _qualityProfile, _rootFolder, _minimumAvailability, monitored)) {
                    Navigator.of(context).pop(['movie_added', entry.title]);
                } else {
                    Notifications.showSnackBar(_scaffoldKey, 'Failed to add movie: Movie might already exist in Radarr');
                }
            },
        );
    }

    Widget _buildAppBar() {
        return AppBar(
            title: Text(
                entry.title,
                style: TextStyle(
                    letterSpacing: Constants.LETTER_SPACING,
                ),
            ),
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(Constants.SECONDARY_COLOR),
            actions: entry.tmdbId != null && entry.tmdbId != 0 ? (
                <Widget>[
                    IconButton(
                        icon: Elements.getIcon(Icons.link),
                        tooltip: 'Open TheMovieDB URL',
                        onPressed: () async {
                            await Functions.openURL('https://www.themoviedb.org/movie/${entry.tmdbId}');
                        },
                    )
                ]
            ) : (
                null
            ),
        );
    }

    Widget _buildList() {
        return Scrollbar(
            child: ListView(
                children: <Widget>[
                    _buildSummary(),
                    Elements.getDivider(),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Monitored'),
                            subtitle: Elements.getSubtitle('Monitor movie for new releases'),
                            trailing: Switch(
                                value: monitored,
                                onChanged: (value) {
                                    setState(() {
                                        monitored = value;
                                    });
                                },
                            ),
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Root Folder'),
                            subtitle: Elements.getSubtitle(_rootFolder.path, preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await RadarrDialogs.showEditRootFolderPrompt(context, _rootFolders);
                                if(_values[0]) {
                                    _rootFolder = _values[1];
                                    setState(() {
                                    });
                                }
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Quality Profile'),
                            subtitle: Elements.getSubtitle(_qualityProfile.name, preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await RadarrDialogs.showEditQualityProfilePrompt(context, _qualityProfiles);
                                if(_values[0]) {
                                    setState(() {
                                        _qualityProfile = _values[1];
                                    });
                                }
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Minimum Availability'),
                            subtitle: Elements.getSubtitle(_minimumAvailability.name, preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await RadarrDialogs.showMinimumAvailabilityPrompt(context, Constants.radarrMinAvailability);
                                if(_values[0]) {
                                    setState(() {
                                        _minimumAvailability = _values[1];
                                    });
                                }
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                ],
                padding: Elements.getListViewPadding(),
            ),
        );
    }

    Widget _buildSummary() {
        return Card(
            child: InkWell(
                child: Row(
                    children: <Widget>[
                        entry.posterURI != null && entry.posterURI != '' ? (
                            ClipRRect(
                                child: Image(
                                    image: AdvancedNetworkImage(
                                        entry.posterURI,
                                        useDiskCache: true,
                                        fallbackAssetImage: 'assets/images/secondary_color.png',
                                        loadFailedCallback: () {},
                                        retryLimit: 1,
                                    ),
                                    height: 100.0,
                                    fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                            )
                         ) : (
                            Container()
                         ),
                        Expanded(
                            child: Padding(
                                child: Text(
                                    '${entry.overview}.\n\n\n',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 4,
                                    style: TextStyle(
                                        color: Colors.white,
                                    ),
                                ),
                                padding: EdgeInsets.all(16.0),
                            ),
                        ),
                    ],
                ),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                onTap: () async {
                    await SystemDialogs.showTextPreviewPrompt(context, entry.title, entry.overview ?? 'No summary is available.');
                },
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }
}
