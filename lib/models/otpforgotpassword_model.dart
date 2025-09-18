// To parse this JSON data, do
//
//     final otPforgotPasswordModel = otPforgotPasswordModelFromJson(jsonString);

import 'dart:convert';

OtPforgotPasswordModel otPforgotPasswordModelFromJson(String str) =>
    OtPforgotPasswordModel.fromJson(json.decode(str));

String otPforgotPasswordModelToJson(OtPforgotPasswordModel data) =>
    json.encode(data.toJson());

class OtPforgotPasswordModel {
  String? message;

  OtPforgotPasswordModel({this.message});

  factory OtPforgotPasswordModel.fromJson(Map<String, dynamic> json) =>
      OtPforgotPasswordModel(message: json["message"]);

  Map<String, dynamic> toJson() => {"message": message};
}
