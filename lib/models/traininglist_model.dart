// To parse this JSON data, do
//
//     final listTrainingModel = listTrainingModelFromJson(jsonString);

import 'dart:convert';

ListTrainingModel listTrainingModelFromJson(String str) =>
    ListTrainingModel.fromJson(json.decode(str));

String listTrainingModelToJson(ListTrainingModel data) =>
    json.encode(data.toJson());

class ListTrainingModel {
  String? message;
  List<Datum>? data;

  ListTrainingModel({this.message, this.data});

  factory ListTrainingModel.fromJson(Map<String, dynamic> json) =>
      ListTrainingModel(
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  int? id;
  String? title;

  Datum({this.id, this.title});

  factory Datum.fromJson(Map<String, dynamic> json) =>
      Datum(id: json["id"], title: json["title"]);

  Map<String, dynamic> toJson() => {"id": id, "title": title};
}
