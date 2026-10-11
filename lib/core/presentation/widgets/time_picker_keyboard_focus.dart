import 'package:flutter/material.dart';

/// Puts the cursor in the hour field when a time picker switches to keyboard
/// entry, so the keyboard opens on the first tap of its icon.
///
/// Pass as `showTimePicker(onEntryModeChanged: focusTimeEntryField)`.
///
/// Tapping the keyboard icon builds the hour and minute fields but focuses
/// neither, so the keyboard stayed shut and the field had to be tapped as
/// well. (The picker's only built-in shortcut for this is double-tapping the
/// dial, which nobody finds.) The dialog's own scope holds focus at that
/// point, and the first stop in its traversal order is the hour field, so
/// advancing focus once lands there and opens the keyboard.
///
/// `reminder_form_screen_test.dart` asserts the hour field really ends up
/// focused, so a change in that traversal order fails loudly rather than
/// quietly focusing a button.
void focusTimeEntryField(TimePickerEntryMode mode) {
  if (mode != TimePickerEntryMode.input) {
    return;
  }
  // The fields do not exist until the frame that switches modes is built.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FocusManager.instance.primaryFocus?.nextFocus();
  });
}
