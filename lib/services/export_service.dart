import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db_service.dart';

class ExportService {
  static Future<void> exportAsPdf() async {
    final pdf = pw.Document();
    final groups = DbService.groupsBox.values.toList();
    final links = DbService.linksBox.values.toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final List<pw.Widget> content = [];
          content.add(
            pw.Header(
              level: 0,
              child: pw.Text("Linku Backup - ${DateTime.now().toIso8601String().split('T').first}"),
            ),
          );

          for (var group in groups) {
            content.add(pw.Header(level: 1, child: pw.Text(group.name)));
            final groupLinks = links.where((l) => l.groupId == group.id).toList();
            if (groupLinks.isEmpty) {
              content.add(pw.Text("No links in this workspace."));
            } else {
              for (var link in groupLinks) {
                content.add(pw.Bullet(text: "${link.title} - ${link.url}"));
              }
            }
            content.add(pw.SizedBox(height: 20));
          }
          return content;
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/linku_export.pdf");
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'Linku PDF Backup');
  }

  static Future<void> exportAsExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue('Workspace'),
      TextCellValue('Title'),
      TextCellValue('URL'),
    ]);

    final groups = DbService.groupsBox.values.toList();
    final links = DbService.linksBox.values.toList();

    for (var link in links) {
      final group = groups.firstWhere(
        (g) => g.id == link.groupId,
        orElse: () => groups.first, // fallback if orphan
      );
      sheet.appendRow([
        TextCellValue(group.name),
        TextCellValue(link.title),
        TextCellValue(link.url),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/linku_export.xlsx");
      await file.writeAsBytes(fileBytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Linku Excel Backup');
    }
  }

  static Future<void> exportAsJson() async {
    final groups = DbService.groupsBox.values.toList();
    final links = DbService.linksBox.values.toList();

    final data = {
      'groups': groups.map((g) => {'id': g.id, 'name': g.name}).toList(),
      'links': links
          .map((l) => {
                'id': l.id,
                'groupId': l.groupId,
                'title': l.title,
                'url': l.url,
                'isFavorite': l.isFavorite,
              })
          .toList(),
    };

    final jsonString = jsonEncode(data);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/linku_backup.json");
    await file.writeAsString(jsonString);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'Linku JSON Backup');
  }
}
