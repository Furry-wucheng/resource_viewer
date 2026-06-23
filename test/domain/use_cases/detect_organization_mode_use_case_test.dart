import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resource_viewer/domain/models/file_entry.dart';
import 'package:resource_viewer/domain/models/resource.dart';
import 'package:resource_viewer/domain/use_cases/detect_organization_mode_use_case.dart';

import '../../helpers/mock_factories.dart';

void main() {
  late MockFileSource source;
  const detect = DetectOrganizationModeUseCase();

  setUp(() => source = MockFileSource());

  test(
    'subfolders containing images without loose files detect chapter',
    () async {
      when(() => source.listDirectory('book')).thenAnswer(
        (_) async => const [
          FileEntry(name: '01', path: 'book/01', isDirectory: true),
        ],
      );
      when(() => source.listDirectory('book/01')).thenAnswer(
        (_) async => const [
          FileEntry(
            name: '001.jpg',
            path: 'book/01/001.jpg',
            isDirectory: false,
          ),
        ],
      );

      expect(await detect(source, 'book'), OrganizationMode.chapter);
    },
  );

  test('mixed subfolders and loose files detect flat grid', () async {
    when(() => source.listDirectory('book')).thenAnswer(
      (_) async => const [
        FileEntry(name: '01', path: 'book/01', isDirectory: true),
        FileEntry(
          name: 'cover.jpg',
          path: 'book/cover.jpg',
          isDirectory: false,
        ),
      ],
    );

    expect(await detect(source, 'book'), OrganizationMode.flatgrid);
  });
}
