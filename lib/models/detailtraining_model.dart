// To parse this JSON data, do
//
//     final detailTrainingModel = detailTrainingModelFromJson(jsonString);

import 'dart:convert';

DetailTrainingModel detailTrainingModelFromJson(String str) =>
    DetailTrainingModel.fromJson(json.decode(str));

String detailTrainingModelToJson(DetailTrainingModel data) =>
    json.encode(data.toJson());

class DetailTrainingModel {
  String? message;
  Data? data;

  DetailTrainingModel({this.message, this.data});

  factory DetailTrainingModel.fromJson(Map<String, dynamic> json) =>
      DetailTrainingModel(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  int? id;
  String? title;
  dynamic description;
  dynamic participantCount;
  dynamic standard;
  dynamic duration;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<dynamic>? units;
  List<dynamic>? activities;

  Data({
    this.id,
    this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.units,
    this.activities,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
    title: json["title"],
    description: json["description"],
    participantCount: json["participant_count"],
    standard: json["standard"],
    duration: json["duration"],
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    units: json["units"] == null
        ? []
        : List<dynamic>.from(json["units"]!.map((x) => x)),
    activities: json["activities"] == null
        ? []
        : List<dynamic>.from(json["activities"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "participant_count": participantCount,
    "standard": standard,
    "duration": duration,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "units": units == null ? [] : List<dynamic>.from(units!.map((x) => x)),
    "activities": activities == null
        ? []
        : List<dynamic>.from(activities!.map((x) => x)),
  };
}
