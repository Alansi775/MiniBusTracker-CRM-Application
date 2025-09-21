import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan; // Excel'den Border ve TextSpan'i gizle
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';

void main() {
  runApp(MinibusTrackerApp());
}

class MinibusTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minibüs Takip Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MinibusTrackerHome(),
    );
  }
}

class Stop {
  String name;
  int durationFromPrevious; // Bir önceki duraktan bu durağa kadar geçmesi gereken süre

  Stop({required this.name, required this.durationFromPrevious});
}

class VehicleRecord {
  String plateNumber;
  String date;
  List<String> arrivalTimes;

  VehicleRecord({
    required this.plateNumber,
    required this.date,
    required this.arrivalTimes,
  });
}

class DelayAnalysis {
  String plateNumber;
  String tripTime;
  int totalDelayMinutes;
  List<StopDelay> stopDelays;
  bool isReturn;

  DelayAnalysis({
    required this.plateNumber,
    required this.tripTime,
    required this.totalDelayMinutes,
    required this.stopDelays,
    this.isReturn = false,
  });
}

class StopDelay {
  String stopName;
  int delayMinutes;
  String expectedTime;
  String actualTime;

  StopDelay({
    required this.stopName,
    required this.delayMinutes,
    required this.expectedTime,
    required this.actualTime,
  });
}

class MinibusTrackerHome extends StatefulWidget {
  @override
  _MinibusTrackerHomeState createState() => _MinibusTrackerHomeState();
}

class _MinibusTrackerHomeState extends State<MinibusTrackerHome> {
  List<Stop> stops = [];
  String referenceStartTime = "06:30";
  int intervalBetweenBuses = 30; // Minibüsler arası dakika (30 dk)
  List<VehicleRecord> vehicleRecords = [];
  List<VehicleRecord> returnRecords = [];
  bool includeReturn = false;
  List<DelayAnalysis> delayAnalyses = [];
  String searchQuery = ""; // Arama sorgusu

  final TextEditingController stopNameController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController intervalController = TextEditingController();
  final TextEditingController searchController = TextEditingController(); // Arama kutusu

  @override
  void initState() {
    super.initState();
    startTimeController.text = referenceStartTime;
    intervalController.text = intervalBetweenBuses.toString();
  }

  // Durak ekleme
  void addStop() {
    if (stopNameController.text.isNotEmpty && durationController.text.isNotEmpty) {
      setState(() {
        stops.add(Stop(
          name: stopNameController.text,
          durationFromPrevious: int.tryParse(durationController.text) ?? 0,
        ));
      });
      stopNameController.clear();
      durationController.clear();
    }
  }

  // Durak silme
  void removeStop(int index) {
    setState(() {
      stops.removeAt(index);
    });
  }

  // Excel dosyası yükleme
  Future<void> uploadExcelFile(bool isReturnFile) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.bytes != null) {
      var bytes = result.files.single.bytes!;
      var excel = Excel.decodeBytes(bytes);

      List<VehicleRecord> records = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;

        // İlk satır başlık olduğu için 1'den başlıyoruz
        for (int row = 1; row < sheet.maxRows; row++) {
          var cells = sheet.rows[row];
          if (cells.isNotEmpty && cells.length >= 3) {
            String plateNumber = cells[0]?.value?.toString() ?? '';
            String date = cells[1]?.value?.toString() ?? '';

            List<String> arrivalTimes = [];
            for (int col = 2; col < cells.length; col++) {
              if (cells[col]?.value != null) {
                arrivalTimes.add(cells[col]!.value.toString());
              }
            }

            if (plateNumber.isNotEmpty && arrivalTimes.isNotEmpty) {
              records.add(VehicleRecord(
                plateNumber: plateNumber,
                date: date,
                arrivalTimes: arrivalTimes,
              ));
            }
          }
        }
      }

      setState(() {
        if (isReturnFile) {
          returnRecords = records;
        } else {
          vehicleRecords = records;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel dosyası başarıyla yüklendi!')),
      );
    }
  }

  // Zaman farkı hesaplama (dakika cinsinden)
  int calculateTimeDifference(String time1, String time2) {
    List<String> time1Parts = time1.split(':');
    List<String> time2Parts = time2.split(':');

    int hours1 = int.parse(time1Parts[0]);
    int minutes1 = int.parse(time1Parts[1]);
    int seconds1 = time1Parts.length > 2 ? int.parse(time1Parts[2]) : 0;

    int hours2 = int.parse(time2Parts[0]);
    int minutes2 = int.parse(time2Parts[1]);
    int seconds2 = time2Parts.length > 2 ? int.parse(time2Parts[2]) : 0;

    int totalMinutes1 = hours1 * 60 + minutes1 + (seconds1 / 60).round();
    int totalMinutes2 = hours2 * 60 + minutes2 + (seconds2 / 60).round();

    return totalMinutes2 - totalMinutes1;
  }

  // Zamana dakika ekleme
  String addMinutesToTime(String time, int minutes) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int mins = int.parse(parts[1]);

    int totalMinutes = hours * 60 + mins + minutes;
    int newHours = (totalMinutes ~/ 60) % 24;
    int newMins = totalMinutes % 60;

    return '${newHours.toString().padLeft(2, '0')}:${newMins.toString().padLeft(2, '0')}';
  }

  // Her Excel satırı için referans kalkış saatini hesapla
  String calculateReferenceStartTimeForRecord(int rowIndex) {
    return addMinutesToTime(referenceStartTime, rowIndex * intervalBetweenBuses);
  }

  // Gecikme analizi yapma
  void analyzeDelays() {
    if (stops.isEmpty || vehicleRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Önce durakları ve Excel dosyasını yükleyin!')),
      );
      return;
    }

    setState(() {
      delayAnalyses.clear();
      referenceStartTime = startTimeController.text;
      intervalBetweenBuses = int.tryParse(intervalController.text) ?? 30;
    });

    // Gidiş analizi - HER EXCEL SATIRI AYRI BİR MİNİBÜS
    for (int i = 0; i < vehicleRecords.length; i++) {
      _analyzeVehicleRecord(vehicleRecords[i], false, i);
    }

    // Dönüş analizi (eğer seçilmişse)
    if (includeReturn && returnRecords.isNotEmpty) {
      for (int i = 0; i < returnRecords.length; i++) {
        _analyzeVehicleRecord(returnRecords[i], true, i);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gecikme analizi tamamlandı!')),
    );
  }

  void _analyzeVehicleRecord(VehicleRecord record, bool isReturn, int rowIndex) {
    List<StopDelay> stopDelays = [];
    int totalDelay = 0;

    if (record.arrivalTimes.isEmpty || stops.isEmpty) return;

    // Bu satırın referans kalkış saati = başlangıç + (satır × aralık dk)
    String thisRecordReferenceTime = calculateReferenceStartTimeForRecord(rowIndex);

    // İLK DURAK - Bu satırın kendi referans saatine göre gecikme
    String actualStartTime = record.arrivalTimes[0];
    int startDelay = calculateTimeDifference(thisRecordReferenceTime, actualStartTime);

    stopDelays.add(StopDelay(
      stopName: stops[0].name + " (Referans: $thisRecordReferenceTime)",
      delayMinutes: startDelay > 0 ? startDelay : 0,
      expectedTime: thisRecordReferenceTime,
      actualTime: actualStartTime,
    ));

    if (startDelay > 0) {
      totalDelay += startDelay;
    }

    // DİĞER DURAKLAR - İki durak arası gerçek süre vs referans süre
    for (int i = 1; i < record.arrivalTimes.length && i < stops.length; i++) {
      // Bir önceki duraktan bu durağa geçen gerçek süre
      String previousStopTime = record.arrivalTimes[i - 1];
      String currentStopTime = record.arrivalTimes[i];
      int actualDuration = calculateTimeDifference(previousStopTime, currentStopTime);

      // Bu segment için referans süre
      int referenceDuration = stops[i].durationFromPrevious;

      // Gecikme = gerçek süre - referans süre
      int segmentDelay = actualDuration - referenceDuration;

      // Beklenen varış saati
      String expectedArrivalTime = addMinutesToTime(previousStopTime, referenceDuration);

      stopDelays.add(StopDelay(
        stopName: stops[i].name + (i == stops.length - 1 ? " (Son Durak)" : ""),
        delayMinutes: segmentDelay > 0 ? segmentDelay : 0,
        expectedTime: expectedArrivalTime,
        actualTime: currentStopTime,
      ));

      if (segmentDelay > 0) {
        totalDelay += segmentDelay;
      }
    }

    delayAnalyses.add(DelayAnalysis(
      plateNumber: record.plateNumber,
      tripTime: thisRecordReferenceTime, // Bu satırın referans kalkış saati
      totalDelayMinutes: totalDelay,
      stopDelays: stopDelays,
      isReturn: isReturn,
    ));
  }

  // PDF oluşturma - Sadece gecikme olanları göster
  Future<void> generatePDF(String plateNumber) async {
    var vehicleAnalyses = delayAnalyses.where((analysis) =>
    analysis.plateNumber == plateNumber).toList();

    if (vehicleAnalyses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu plaka için analiz bulunamadı!')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Minibus Gecikme Raporu - $plateNumber',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            ...vehicleAnalyses.map((analysis) {
              // Sadece gecikme olan durakları filtrele
              var delayedStops = analysis.stopDelays.where((stop) => stop.delayMinutes > 0).toList();

              return pw.Container(
                margin: pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Referans Kalkis: ${analysis.tripTime} ${analysis.isReturn ? "(Donus)" : "(Gidis)"}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    if (analysis.totalDelayMinutes == 0)
                      pw.Text('✓ Arac gecikme yasamadi - Tum duraklar zamaninda',
                          style: pw.TextStyle(color: PdfColors.green, fontSize: 12))
                    else ...[
                      pw.Text('Toplam Gecikme: ${analysis.totalDelayMinutes} dakika',
                          style: pw.TextStyle(color: PdfColors.red, fontSize: 12)),
                      pw.SizedBox(height: 10),
                      if (delayedStops.isNotEmpty)
                        pw.Table.fromTextArray(
                          headers: ['Geciken Durak', 'Beklenen Varis', 'Gercek Varis', 'Gecikme (dk)'],
                          data: delayedStops.map((stopDelay) => [
                            _turkishToAscii(stopDelay.stopName),
                            stopDelay.expectedTime,
                            stopDelay.actualTime,
                            stopDelay.delayMinutes.toString(),
                          ]).toList(),
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                          cellStyle: pw.TextStyle(fontSize: 10),
                          headerDecoration: pw.BoxDecoration(color: PdfColors.red100),
                          cellAlignment: pw.Alignment.centerLeft,
                        ),
                    ],
                    pw.SizedBox(height: 10),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Arama metnini vurgulama
  List<TextSpan> _highlightSearchText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        // Kalan metni ekle
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      // Eşleşmeden önceki metni ekle
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Eşleşen metni vurgula
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow[300],
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }

  // Türkçe karakterleri ASCII'ye çevirme (geçici çözüm)
  String _turkishToAscii(String text) {
    return text
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U');
  }

  // Plaka listesini al (arama filtreli)
  List<String> getUniqueVehiclePlates() {
    Set<String> plates = {};
    for (var record in vehicleRecords) {
      plates.add(record.plateNumber);
    }
    for (var record in returnRecords) {
      plates.add(record.plateNumber);
    }

    List<String> sortedPlates = plates.toList()..sort();

    // Arama filtresi uygula
    if (searchQuery.isNotEmpty) {
      return sortedPlates.where((plate) =>
          plate.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    return sortedPlates;
  }

  // Arama fonksiyonu
  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
  }

  // Arama kutusunu temizle
  void clearSearch() {
    setState(() {
      searchQuery = "";
      searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minibüs Takip Sistemi'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol panel - Durak yönetimi
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Önemli: Column'un boyutunu sınırla
                    children: [
                      Text('Durak Yönetimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),

                      // Başlangıç saati ve aralık
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startTimeController,
                              decoration: InputDecoration(
                                labelText: 'İlk Minibüs Kalkış Saati (HH:MM)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: intervalController,
                              decoration: InputDecoration(
                                labelText: 'Minibüs Aralığı (dk)',
                                border: OutlineInputBorder(),
                                hintText: '30',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🚌 Örnek: İlk minibüs 06:30, aralık 30dk → 2. minibüs 07:00, 3. minibüs 07:30...',
                          style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Durak ekleme
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: stopNameController,
                              decoration: InputDecoration(
                                labelText: 'Durak Adı',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              decoration: InputDecoration(
                                labelText: 'Önceki duraktan buraya (dk)',
                                border: OutlineInputBorder(),
                                hintText: 'Örn: 12',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: addStop,
                            child: Text('Ekle'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '💡 İpucu: İlk durak için "0" girin. Diğer duraklar için önceki duraktan bu durağa kadar geçmesi gereken dakikayı girin.',
                          style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Durak listesi
                      Text('Duraklar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Container(
                        height: 300, // Sabit yükseklik ver
                        child: ListView.builder(
                          itemCount: stops.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text('${index + 1}')),
                                title: Text(stops[index].name),
                                subtitle: Text(index == 0 ? 'Başlangıç durağı' : 'Önceki duraktan: ${stops[index].durationFromPrevious} dk${index == stops.length - 1 ? " (Son Durak)" : ""}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => removeStop(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Sağ panel - Dosya yükleme ve analiz
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Column boyutunu sınırla
                children: [
                  // Dosya yükleme
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Dosya Yükleme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),

                          ElevatedButton.icon(
                            onPressed: () => uploadExcelFile(false),
                            icon: Icon(Icons.upload_file),
                            label: Text('Gidiş Excel Dosyası Yükle'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                          SizedBox(height: 8),
                          Text('Yüklenen kayıt sayısı: ${vehicleRecords.length}'),

                          SizedBox(height: 16),

                          CheckboxListTile(
                            title: Text('Dönüş Seferlerini Dahil Et'),
                            value: includeReturn,
                            onChanged: (value) {
                              setState(() {
                                includeReturn = value ?? false;
                              });
                            },
                          ),

                          if (includeReturn) ...[
                            ElevatedButton.icon(
                              onPressed: () => uploadExcelFile(true),
                              icon: Icon(Icons.upload_file),
                              label: Text('Dönüş Excel Dosyası Yükle'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            ),
                            SizedBox(height: 8),
                            Text('Dönüş kayıt sayısı: ${returnRecords.length}'),
                          ],

                          SizedBox(height: 16),

                          ElevatedButton.icon(
                            onPressed: analyzeDelays,
                            icon: Icon(Icons.analytics),
                            label: Text('Gecikme Analizi Yap'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),

                          SizedBox(height: 16),

                          // Excel satır referans saatleri gösterici
                          if (vehicleRecords.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Excel Satır Referans Kalkış Saatleri:',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                                  SizedBox(height: 8),
                                  ...vehicleRecords.take(10).map((record) {
                                    int index = vehicleRecords.indexOf(record);
                                    String refTime = addMinutesToTime(referenceStartTime, index * intervalBetweenBuses);
                                    return Text('${index + 1}. ${record.plateNumber} → $refTime',
                                        style: TextStyle(fontSize: 12, color: Colors.blue[700]));
                                  }).toList(),
                                  if (vehicleRecords.length > 10)
                                    Text('...ve ${vehicleRecords.length - 10} kayıt daha',
                                        style: TextStyle(fontSize: 12, color: Colors.blue[600])),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Plaka listesi
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Araç Listesi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              if (searchQuery.isNotEmpty)
                                Text('(${getUniqueVehiclePlates().length} sonuç)',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Arama kutusu
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  onChanged: onSearchChanged,
                                  decoration: InputDecoration(
                                    labelText: 'Plaka Ara',
                                    hintText: '35BNV175',
                                    prefixIcon: Icon(Icons.search),
                                    suffixIcon: searchQuery.isNotEmpty
                                        ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: clearSearch,
                                    )
                                        : null,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Sonuç sayısı ve durum bilgisi
                          if (getUniqueVehiclePlates().isEmpty && searchQuery.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                                  SizedBox(width: 8),
                                  Text('"$searchQuery" için sonuç bulunamadı',
                                      style: TextStyle(color: Colors.orange[800])),
                                ],
                              ),
                            )
                          else if (searchQuery.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${getUniqueVehiclePlates().length} plaka bulundu',
                                  style: TextStyle(fontSize: 12, color: Colors.green[800])),
                            ),

                          SizedBox(height: 8),

                          Container(
                            height: 350, // Arama kutusu için biraz daha kısa
                            child: getUniqueVehiclePlates().isEmpty
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'Plaka bulunamadı'
                                        : 'Henüz araç analizi yapılmadı',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                                : ListView.builder(
                              itemCount: getUniqueVehiclePlates().length,
                              itemBuilder: (context, index) {
                                String plateNumber = getUniqueVehiclePlates()[index];
                                var vehicleAnalyses = delayAnalyses.where(
                                        (analysis) => analysis.plateNumber == plateNumber).toList();

                                int totalDelays = vehicleAnalyses.fold(0,
                                        (sum, analysis) => sum + analysis.totalDelayMinutes);

                                return Card(
                                  elevation: searchQuery.isNotEmpty ? 3 : 1, // Arama yapılıyorsa daha belirgin
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: totalDelays == 0 ? Colors.green : Colors.red,
                                      child: Icon(
                                        totalDelays == 0 ? Icons.check : Icons.warning,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: RichText(
                                      text: TextSpan(
                                        children: _highlightSearchText(plateNumber, searchQuery),
                                        style: TextStyle(color: Colors.black, fontSize: 16),
                                      ),
                                    ),
                                    subtitle: Text(
                                      totalDelays == 0
                                          ? 'Gecikme yok'
                                          : 'Toplam gecikme: $totalDelays dk',
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.picture_as_pdf),
                                      onPressed: () => generatePDF(plateNumber),
                                    ),
                                    onTap: () => generatePDF(plateNumber),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}