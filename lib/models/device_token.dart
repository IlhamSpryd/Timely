// To parse this JSON data, do
//
//     final deviceTokenModel = deviceTokenModelFromJson(jsonString);

import 'dart:convert';

DeviceTokenModel deviceTokenModelFromJson(String str) =>
    DeviceTokenModel.fromJson(json.decode(str));

String deviceTokenModelToJson(DeviceTokenModel data) =>
    json.encode(data.toJson());

class DeviceTokenModel {
  String? message;
  Data? data;

  DeviceTokenModel({this.message, this.data});

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) =>
      DeviceTokenModel(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  int? userId;
  String? playerId;

  Data({this.userId, this.playerId});

  factory Data.fromJson(Map<String, dynamic> json) =>
      Data(userId: json["user_id"], playerId: json["player_id"]);

  Map<String, dynamic> toJson() => {"user_id": userId, "player_id": playerId};
}
