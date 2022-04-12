import 'dart:convert';
import 'dart:io';

import 'package:fuzzy/fuzzy.dart';

void main(List<String> arguments) {
  init(arguments);
}

void init(List<String> arguments) async {
  final String data = File('station_data.json').readAsStringSync();
  final String vrnData = File('vrnstations.json').readAsStringSync();

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

    Map<String, dynamic> jsonResultVRN = json.decode(vrnData) as Map<String, dynamic>;
    for (Map<String, dynamic>? s in jsonResultVRN["vrnStations"]["elements"]) {
      if (s == null) continue;
      final station = Station.fromJsonVRN(s);
      if (station.id != null) {
        if (_stationsLocalData.indexWhere((s) => s.id == station.id) == -1) {
          _stationsLocalData.add(station);
        }
      }
    }

    final fuse = Fuzzy(
      _stationsLocalData,
      options: FuzzyOptions(
        isCaseSensitive: false,
        matchAllTokens: false,
        shouldSort: true,
        findAllMatches: false,
        tokenize: true,
        shouldNormalize: true,
        minMatchCharLength: 2,
        minTokenCharLength: 2,
        location: 0,
        threshold: 0.4,
        distance: 80,
        //verbose: false,
        keys: [
          WeightedKey<Station>(
            name: 'name',
            getter: (station) => station.name,
            weight: 10,
          ),
          WeightedKey<Station>(
            name: 'longname',
            getter: (station) => station.longName,
            weight: 1,
          ),
          WeightedKey<Station>(
            name: 'place',
            getter: (station) => station.place,
            weight: 10,
          ),
        ],
      ),
    );


    var str = '';

    for(final argument in arguments){
      str = str + argument + " ";
    }

    str = str.trim();
    final normalizedString = splitSortAndUnique(str);

    print('|${normalizedString}|');

    final result = fuse.search(normalizedString);

    result.take(10).forEach((r) {
      print('${r.item.search} | ${r.score}');
    });
  } catch (e) {
    print(e);
  }
}

class Station {
  final String? id;
  final String longName;
  final String place;
  final String name;
  final String search;

  Station.fromJson(Map<String, dynamic> data)
      : id = data['globalID'] as String,
        longName = (data['longName'] as String?) ?? '',
        name = (data['name'] as String?) ?? '',
        place = (data['place'] as String?) ?? '',
        search = splitSortAndUnique(((data['name'] as String?) ?? '') + " " + ((data['longName'] as String?) ?? '') + " " + ((data['place'] as String?) ?? ''));

  Station.fromJsonVRN(Map<String, dynamic> data)
      : id = data['point']['station']['globalID'] as String,
        longName = (data['point']['station']['name'] as String?) ?? '',
        name = (data['point']['station']['name'] as String?) ?? '',
        place = (data['place'] as String?) ?? '',
        search = splitSortAndUnique(((data['point']['station']['name'] as String?) ?? '') + " " + ((data['place'] as String?) ?? ''));
}

 String splitSortAndUnique(String string) {
  var array = string.split(" ");
  array.sort();
  final sortAndUnique =  array.toSet().toList();
  return sortAndUnique.join(" ").toLowerCase();
}
