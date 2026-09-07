#!/bin/bash
# intl_translation is no longer a project dependency (it pins intl < 0.20,
# which blocks Flutter >= 3.24): run it from the global pub cache instead.
#   dart pub global activate intl_translation
set -e

dart pub global run intl_translation:extract_to_arb --output-dir=assets/l10n/ $(find lib -name '*.dart' | grep -v l10n/messages_)
cp assets/l10n/intl_messages.arb lib/l10n/intl_en.arb && \
cp assets/l10n/intl_messages.arb lib/l10n/intl_es.arb && \
cp assets/l10n/intl_messages.arb lib/l10n/intl_fr.arb
dart pub global run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading $(find lib -name '*.dart') lib/l10n/intl_*.arb
