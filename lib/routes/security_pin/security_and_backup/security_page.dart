import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez/bloc/backup/backup_bloc.dart';
import 'package:breez/bloc/backup/backup_model.dart';
import 'package:breez/bloc/user_profile/breez_user_model.dart';
import 'package:breez/bloc/user_profile/user_actions.dart';
import 'package:breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:breez/routes/backup_in_progress_dialog.dart';
import 'package:breez/routes/security_pin/lock_screen.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/backup_provider_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/change_pin_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/disable_pin_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/enable_biometric_auth_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/generate_backup_phrase_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/pin_interval_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/security_pin_tiles/remote_server_credentials_tile.dart';
import 'package:breez/routes/security_pin/security_and_backup/widgets/last_backup_text.dart';
import 'package:breez/widgets/back_button.dart' as backBtn;
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SecurityPage extends StatefulWidget {
  final UserProfileBloc userProfileBloc;
  final BackupBloc backupBloc;

  const SecurityPage(
    this.userProfileBloc,
    this.backupBloc, {
    Key key,
  }) : super(key: key);

  @override
  SecurityPageState createState() {
    return SecurityPageState();
  }
}

class SecurityPageState extends State<SecurityPage>
    with WidgetsBindingObserver {
  StreamSubscription<BackupState> _backupInProgressSubscription;
  final _autoSizeGroup = AutoSizeGroup();
  bool _screenLocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initListeners();
    });
  }

  @override
  void dispose() {
    widget.userProfileBloc.userActionsSink.add(StopBiometrics());
    WidgetsBinding.instance.removeObserver(this);
    _backupInProgressSubscription?.cancel();
    super.dispose();
  }

  void _initListeners() {
    /// Subscribing to backups in progress such as here will also block the UI
    /// for other sources of backups outside this page such as
    /// receiving an onchain payment.
    _backupInProgressSubscription = widget.backupBloc.backupStateStream
        .where((s) => s.inProgress)
        .listen((s) async {
      if (mounted) {
        EasyLoading.dismiss();

        await showDialog(
          useRootNavigator: false,
          barrierDismissible: false,
          context: context,
          builder: (context) => buildBackupInProgressDialog(
            context,
            widget.backupBloc.backupStateStream,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return StreamBuilder<BackupSettings>(
      stream: widget.backupBloc.backupSettingsStream,
      builder: (context, backupSnapshot) => StreamBuilder<BreezUserModel>(
        stream: widget.userProfileBloc.userStream,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !backupSnapshot.hasData) {
            return Container();
          }

          final requiresPin = userSnapshot.data.securityModel.requiresPin;
          final backupProvider = backupSnapshot.data.backupProvider;
          final isRemoteServer = backupProvider?.name ==
              BackupSettings.remoteServerBackupProvider().name;

          if (requiresPin && _screenLocked) {
            return AppLockScreen(_validatePinCode, canCancel: true);
          }

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: const backBtn.BackButton(),
              title: Text(texts.security_and_backup_title),
            ),
            body: ListView(
              children: [
                DisablePinTile(
                  userProfileBloc: widget.userProfileBloc,
                  unlockScreen: _setScreenLocked,
                  autoSizeGroup: _autoSizeGroup,
                ),
                if (requiresPin) ...[
                  const Divider(),
                  PinIntervalTile(
                    userProfileBloc: widget.userProfileBloc,
                    unlockScreen: _setScreenLocked,
                    autoSizeGroup: _autoSizeGroup,
                  ),
                  const Divider(),
                  ChangePinTile(
                    userProfileBloc: widget.userProfileBloc,
                    unlockScreen: _setScreenLocked,
                    autoSizeGroup: _autoSizeGroup,
                  ),
                  const Divider(),
                  EnableBiometricAuthTile(
                    userProfileBloc: widget.userProfileBloc,
                    unlockScreen: _setScreenLocked,
                    autoSizeGroup: _autoSizeGroup,
                  ),
                ],
                const Divider(),
                BackupProviderTile(
                  backupBloc: widget.backupBloc,
                  autoSizeGroup: _autoSizeGroup,
                ),
                if (isRemoteServer) ...[
                  const Divider(),
                  RemoteServerCredentialsTile(
                    backupBloc: widget.backupBloc,
                    autoSizeGroup: _autoSizeGroup,
                  ),
                ],
                const Divider(),
                GenerateBackupPhraseTile(
                  backupBloc: widget.backupBloc,
                  autoSizeGroup: _autoSizeGroup,
                ),
              ],
            ),
            bottomNavigationBar: const Padding(
              padding: EdgeInsets.only(
                bottom: 20.0,
                left: 20.0,
                top: 20.0,
              ),
              child: LastBackupText(),
            ),
          );
        },
      ),
    );
  }

  Future<dynamic> _validatePinCode(pinEntered) {
    final validateAction = ValidatePinCode(pinEntered);
    widget.userProfileBloc.userActionsSink.add(validateAction);
    return validateAction.future.then((_) => _setScreenLocked(false));
  }

  void _setScreenLocked(bool value) {
    setState(() {
      _screenLocked = value;
    });
  }
}
