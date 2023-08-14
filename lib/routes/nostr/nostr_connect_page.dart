import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez/utils/nostrConnect.dart';
import 'package:flutter/material.dart';
import 'package:breez/theme_data.dart' as theme;

import '../../bloc/nostr/nostr_actions.dart';
import '../../bloc/nostr/nostr_bloc.dart';
import '../../utils/min_font_size.dart';

class NostrConnectPage extends StatefulWidget {
  final NostrBloc nostrBloc;
  const NostrConnectPage({Key key, this.nostrBloc}) : super(key: key);

  @override
  State<NostrConnectPage> createState() => _NostrConnectPageState();
}

class _NostrConnectPageState extends State<NostrConnectPage> {
  final _autoSizeGroup = AutoSizeGroup();
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<ConnectUri> connectedApps = [];
  bool isAdd = false;

  @override
  void initState() {
    super.initState();
    // calling a method via nostr Bloc to listen to requests (NIP47)
  }

  Future<void> _addApp(String connectUrl, NostrBloc nostrBloc) async {
    // app to be added
    ConnectUri nostrConnectUri = fromConnectUri(connectUrl);

    // check if connectedApps Already has this app

    // add a nostr bloc method here

    bool connect = await approveConnectModal(context, nostrConnectUri);

    if (!connect) return;

    nostrBloc.actionsSink.add(Nip47Connect(
      connectUri: nostrConnectUri,
      nostrBloc: nostrBloc,
    ));

    String connectAppId = await nostrBloc.nip47ConnectStream.first;

    if (connectAppId == nostrConnectUri.target &&
        !connectedApps.contains(nostrConnectUri)) {
      setState(() {
        connectedApps.add(nostrConnectUri);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nostr"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            ListTile(
              title: Container(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: "Connect to a new Nostr app (NIP-47)"),
                  style: theme.FieldTextStyle.textStyle,
                  controller: _textEditingController,
                  focusNode: _focusNode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    return value != null ? null : "please enter a value";
                  },
                  onTapOutside: (value) {
                    _focusNode.unfocus();
                  },
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () async {
                  await _addApp(
                      _textEditingController.text.trim(), widget.nostrBloc);
                  _textEditingController.clear();
                },
                child: const Text("Connect"),
              ),
            ),
            const Divider(),
            if (connectedApps.isNotEmpty)
              ...connectedApps.asMap().entries.map(
                (entry) {
                  ConnectUri app = entry.value;
                  int ind = entry.key;
                  return Column(
                    children: [
                      ListTile(
                        title: AutoSizeText(
                          app.metadata['name'],
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          minFontSize: MinFontSize(context).minFontSize,
                          stepGranularity: 0.1,
                          group: _autoSizeGroup,
                        ),
                        trailing: const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.white,
                          size: 30.0,
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
