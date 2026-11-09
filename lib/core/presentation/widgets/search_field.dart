import 'package:flutter/material.dart';

/// The search box above a list.
///
/// Shared by the archive's searchable lists so they cannot drift into looking
/// or behaving differently, the same reason the two-pane list width is shared.
///
/// The [controller] belongs to the screen rather than to this widget. A screen
/// clears the query from more than one place -- the button in here, and
/// whatever else resets its list -- and if the text lived in here those two
/// could disagree, leaving a box with words in it above an unfiltered list.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;

  /// What this list is searched by, in the user's terms -- it is the only
  /// hint about how much of a record the search reaches into.
  final String hintText;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      // Rebuilt from the controller so the clear button appears and goes with
      // the text however the text changed, including a clear from elsewhere
      // on the screen.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            // The query filters an in-memory list as it is typed, so there is
            // nothing to submit and no reason to make someone press return.
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          );
        },
      ),
    );
  }
}
