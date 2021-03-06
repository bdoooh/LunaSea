import 'package:flutter/material.dart';
import 'package:lunasea/configuration/configuration.dart';
import 'package:lunasea/configuration/profiles.dart';
import 'package:lunasea/system/ui.dart';

class Profile extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return _ProfileWidget();
    }
}

class _ProfileWidget extends StatefulWidget {
    @override
    State<StatefulWidget> createState() {
        return _ProfileState();
    }
}

class _ProfileState extends State<StatefulWidget> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    String _enabled;
    List<String> _profiles;

    @override
    void initState() {
        super.initState();
        _refreshData();
    }

    void _refreshData() {
        setState(() {
            _enabled = Profiles.enabledProfile;
            _profiles = Profiles.profileList;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            body: _profileSettings(),
        );
    }

    Widget _profileSettings() {
        return Scrollbar(
            child: ListView(
                children: <Widget>[
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Enabled Profile'),
                            subtitle: Elements.getSubtitle(_enabled),
                            onTap: () async {
                                List<String> sortedProfiles = List.from(_profiles);
                                sortedProfiles.sort((a,b) => a.compareTo(b));
                                List<dynamic> values = await SystemDialogs.showChangeProfilePrompt(context, sortedProfiles);
                                if(values[0]) {
                                    if(values[1] != _enabled) {
                                        await Profiles.setProfile(values[1]);
                                        Navigator.of(context).popAndPushNamed('/settings');
                                    }
                                }
                            },
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Add'),
                            subtitle: Elements.getSubtitle('Add a new profile'),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.add),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showAddProfilePrompt(context);
                                if(_values[0]) {
                                    if(_profiles.contains(_values[1])) {
                                        Notifications.showSnackBar(_scaffoldKey, 'Unable to add profile: Name already exists');
                                    } else {
                                        _enabled = _values[1];
                                        await Profiles.createProfile(_values[1]);
                                        await Configuration.pullAndSanitizeValues();
                                        Notifications.showSnackBar(_scaffoldKey, 'Profile added');
                                        _refreshData();
                                    }
                                }
                            }
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Delete'),
                            subtitle: Elements.getSubtitle('Delete an existing profile'),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.delete),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showDeleteProfilePrompt(context, _profiles);
                                if(_values[0]) {
                                    if(_values[1] == Profiles.enabledProfile) {
                                        Notifications.showSnackBar(_scaffoldKey, 'Cannot delete enabled profile');
                                    } else {
                                        await Profiles.deleteProfile(_values[1]);
                                        await Configuration.pullAndSanitizeValues();
                                        Notifications.showSnackBar(_scaffoldKey, 'Profile deleted');
                                        _refreshData();
                                    }
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
}
