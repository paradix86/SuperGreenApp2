/*
 * Copyright (C) 2022  SuperGreenLab <towelie@supergreenlab.com>
 * Author: Constantin Clauzel <constantin.clauzel@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:intl/intl.dart';
import 'package:super_green_app/l10n.dart';

class CommonL10N {
  static String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: 'Loading message usually displayed on the fullscreen overlay',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get saving {
    return Intl.message(
      'Saving...',
      name: 'saving',
      desc: 'Saving message usually displayed on the fullscreen overlay',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingParameters {
    return Intl.message(
      'Setting parameters..',
      name: 'settingParameters',
      desc: 'Setting parameter message usually displayed on the fullscreen overlay',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get done {
    return Intl.message(
      'Done!',
      name: 'done',
      desc: 'Success message usually displayed on the fullscreen overlay',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get doneButton {
    return Intl.message(
      'DONE',
      name: 'doneButton',
      desc: '"Done" label for confirmation buttons',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get no {
    return Intl.message(
      'NO',
      name: 'no',
      desc: 'Used in confirmation dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get yes {
    return Intl.message(
      'YES',
      name: 'yes',
      desc: 'Used in confirmation dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: 'Used in confirmation dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get or {
    return Intl.message(
      'OR',
      name: 'or',
      desc: 'Used in confirmation dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get cancel {
    return Intl.message(
      'CANCEL',
      name: 'cancel',
      desc: 'Used in confirmation dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get loginCreateAccount {
    return Intl.message(
      'LOGIN / CREATE ACCOUNT',
      name: 'loginCreateAccount',
      desc: 'Used in "please login" dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get loginRequiredDialogTitle {
    return Intl.message(
      'Login required',
      name: 'loginRequiredDialogTitle',
      desc: 'Used in "please login" dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get loginRequiredDialogBody {
    return Intl.message(
      'Please log in or create an account.',
      name: 'loginRequiredDialogBody',
      desc: 'Used in "please login" dialogs',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get unsavedChangeDialogTitle {
    return Intl.message(
      'Unsaved changes',
      name: 'unsavedChangeDialogTitle',
      desc: 'Title for the "unsaved changes" dialog when pressing back',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get unsavedChangeDialogBody {
    return Intl.message(
      'Changes will not be saved. Continue?',
      name: 'unsavedChangeDialogBody',
      desc: 'Body for the "unsaved changes" dialog when pressing back',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get confirmUnRevertableChange {
    return Intl.message(
      'This can\'t be reverted. Continue?',
      name: 'confirmUnRevertableChange',
      desc: 'Body for the delete dialog confirmation',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get commandSent {
    return Intl.message(
      'Command sent.',
      name: 'commandSent',
      desc: 'Snackbar shown after a controller command succeeded',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get commandFailed {
    return Intl.message(
      'Command failed. Please retry.',
      name: 'commandFailed',
      desc: 'Snackbar shown after a controller command failed',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get undoApplied {
    return Intl.message(
      'Undo applied.',
      name: 'undoApplied',
      desc: 'Snackbar shown after a controller command was reverted',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get unableToCancelChanges {
    return Intl.message(
      'Unable to cancel changes. Please retry.',
      name: 'unableToCancelChanges',
      desc: 'Snackbar shown when reverting controller changes failed',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get undoButton {
    return Intl.message(
      'UNDO 10s',
      name: 'undoButton',
      desc: 'Snackbar action label to revert a controller command within 10 seconds',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get connectionBadgeOffline {
    return Intl.message(
      'OFFLINE',
      name: 'connectionBadgeOffline',
      desc: 'Controller connection badge: not reachable',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get connectionBadgeStale {
    return Intl.message(
      'STALE',
      name: 'connectionBadgeStale',
      desc: 'Controller connection badge: last data older than 30 seconds',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get connectionBadgeRemote {
    return Intl.message(
      'REMOTE',
      name: 'connectionBadgeRemote',
      desc: 'Controller connection badge: reached through the cloud',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get connectionBadgeLocal {
    return Intl.message(
      'LOCAL',
      name: 'connectionBadgeLocal',
      desc: 'Controller connection badge: reached on the local network',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get connectionBadgeNoController {
    return Intl.message(
      'OFFLINE - no controller linked',
      name: 'connectionBadgeNoController',
      desc: 'Controller connection badge: the box has no controller',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String updatedAgo(String age) {
    return Intl.message(
      'Updated $age ago',
      args: [age],
      name: 'updatedAgo',
      desc: 'Age of the last controller data, e.g. "Updated 12s ago"',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get justNow {
    return Intl.message(
      'just now',
      name: 'justNow',
      desc: 'Age label when the last controller data is less than 5 seconds old',
      locale: SGLLocalizations.current?.localeName,
    );
  }
}
