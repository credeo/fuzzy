import 'dart:convert';
import 'dart:io';

import 'package:fuzzy/fuzzy.dart';

void main() {
  init();
}

void init() async {
  final String data = File('station_data.json').readAsStringSync();

  try {
    Map<String, dynamic> jsonResult = json.decode(data) as Map<String, dynamic>;
    List<Station> _stationsLocalData = [];
    for (Map<String, dynamic>? s in jsonResult["stations"]["elements"]) {
      if (s == null) continue;
      final station = Station.fromJson(s);
      if (station.id != null) {
        _stationsLocalData.add(station);
      }
    }
    final fuse = Fuzzy(
      _stationsLocalData,
      options: FuzzyOptions(
        isCaseSensitive: false,
        shouldSort: true,
        findAllMatches: true,
        minMatchCharLength: 1,
        location: 0,
        threshold: 0.5,
        distance: 100,
        keys: [
          WeightedKey<Station>(
            name: 'longName',
            getter: (station) => station.longName,
            weight: 1,
          ),
          WeightedKey<Station>(
            name: 'place',
            getter: (station) => station.place,
            weight: 1,
          ),
        ],
      ),
    );

    final result = fuse.search('planeta');

    print('A score of 0 indicates a perfect match, while a score of 1 indicates a complete mismatch.');

    result.forEach((r) {
      print('\nScore: ${r.score}\nstation: ${r.item.longName} ${r.item.place}');
    });
  } catch (e) {
    print(e);
  }
}

class Station {
  final String? id;
  final String longName;
  final String place;

  Station.fromJson(Map<String, dynamic> data)
      : id = data['id'] as String,
        longName = (data['longName'] as String?) ?? '',
        place = (data['place'] as String?) ?? '';
}
