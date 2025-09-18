// To parse this JSON data, do
//
//     final absenStatsModel = absenStatsModelFromJson(jsonString);

import 'dart:convert';

AbsenStatsModel absenStatsModelFromJson(String str) =>
    AbsenStatsModel.fromJson(json.decode(str));

String absenStatsModelToJson(AbsenStatsModel data) =>
    json.encode(data.toJson());

class AbsenStatsModel {
  String? message;
  Data? data;

  AbsenStatsModel({this.message, this.data});

  factory AbsenStatsModel.fromJson(Map<String, dynamic> json) =>
      AbsenStatsModel(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  int? totalAbsen;
  int? totalMasuk;
  int? totalIzin;
  bool? sudahAbsenHariIni;

  Data({
    this.totalAbsen,
    this.totalMasuk,
    this.totalIzin,
    this.sudahAbsenHariIni,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    totalAbsen: json["total_absen"],
    totalMasuk: json["total_masuk"],
    totalIzin: json["total_izin"],
    sudahAbsenHariIni: json["sudah_absen_hari_ini"],
  );

  Map<String, dynamic> toJson() => {
    "total_absen": totalAbsen,
    "total_masuk": totalMasuk,
    "total_izin": totalIzin,
    "sudah_absen_hari_ini": sudahAbsenHariIni,
  };
}
