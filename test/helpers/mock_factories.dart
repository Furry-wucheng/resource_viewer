import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/shared/file_source/smb_file_source.dart';
import 'package:resource_viewer/shared/file_source/file_source.dart';
import 'package:resource_viewer/data/repositories/settings_repository.dart';

class MockSmbPoolClient extends Mock implements SmbPoolClient {}

class MockFileSource extends Mock implements FileSource {}

class MockSettingsRepository extends Mock implements SettingsRepository {}
