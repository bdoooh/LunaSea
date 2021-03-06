import 'package:flutter/material.dart';
import 'package:lunasea/configuration/values.dart';
import 'package:lunasea/logic/clients/sabnzbd.dart';
import 'package:lunasea/system/ui.dart';

class SABnzbd extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return _SABnzbdWidget();
    }
}

class _SABnzbdWidget extends StatefulWidget {
    @override
    State<StatefulWidget> createState() {
        return _SABnzbdState();
    }
}

class _SABnzbdState extends State<StatefulWidget> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    List<dynamic> _sabnzbdValues;

    @override
    void initState() {
        super.initState();
        _refreshData();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            body: _sabnzbdSettings(),
            floatingActionButton: _buildFloatingActionButton(),
        );
    }

    void _refreshData() {
        setState(() {
            _sabnzbdValues = List.from(Values.sabnzbdValues);
        });
    }

    Widget _buildFloatingActionButton() {
        return FloatingActionButton(
            heroTag: null,
            tooltip: 'Test & Save',
            child: Elements.getIcon(Icons.save),
            onPressed: () async {
                if(await SABnzbdAPI.testConnection(_sabnzbdValues)) {
                    await Values.setSabnzbd(_sabnzbdValues);
                    _refreshData();
                    Notifications.showSnackBar(_scaffoldKey, 'Settings saved');
                } else {
                    Notifications.showSnackBar(_scaffoldKey, 'Connection test failed: Settings not saved');
                }
            },
        );
    }

    Widget _sabnzbdSettings() {
        return Scrollbar(
            child: ListView(
                children: <Widget>[
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Enable SABnzbd'),
                            trailing: Switch(
                                value: _sabnzbdValues[0],
                                onChanged: (value) {
                                    setState(() {
                                        _sabnzbdValues[0] = value;
                                    });
                                },
                            ),
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Host'),
                            subtitle: Elements.getSubtitle(_sabnzbdValues[1] == '' ? 'Not Set' : _sabnzbdValues[1], preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showEditTextPrompt(context, 'SABnzbd Host', prefill: _sabnzbdValues[1]);
                                if(_values[0]) {
                                    setState(() {
                                        _sabnzbdValues[1] = _values[1];
                                    });
                                }
                            }
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('API Key'),
                            subtitle: Elements.getSubtitle(_sabnzbdValues[2] == '' ? 'Not Set' : _sabnzbdValues[2], preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showEditTextPrompt(context, 'SABnzbd API Key', prefill: _sabnzbdValues[2]);
                                if(_values[0]) {
                                    setState(() {
                                        _sabnzbdValues[2] = _values[1];
                                    });
                                }
                            }
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
