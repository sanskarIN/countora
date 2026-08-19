import 'package:url_launcher/url_launcher.dart';

typedef ExternalUriOpener = Future<bool> Function(Uri uri);

/// Opens external URIs without allowing platform-channel failures to escape into
/// the widget tree.
///
/// The optional [opener] keeps failure behavior deterministic in unit tests and
/// avoids requiring a real platform URL handler there.
Future<bool> openExternalUri(
  Uri uri, {
  ExternalUriOpener? opener,
}) async {
  try {
    return await (opener ?? launchUrl)(uri);
  } on Object {
    return false;
  }
}
