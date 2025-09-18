// To parse this JSON data, do
//
//     final editPhotoProfileModel = editPhotoProfileModelFromJson(jsonString);

import 'dart:convert';

EditPhotoProfileModel editPhotoProfileModelFromJson(String str) =>
    EditPhotoProfileModel.fromJson(json.decode(str));

String editPhotoProfileModelToJson(EditPhotoProfileModel data) =>
    json.encode(data.toJson());

class EditPhotoProfileModel {
  String? message;
  Data? data;

  EditPhotoProfileModel({this.message, this.data});

  factory EditPhotoProfileModel.fromJson(Map<String, dynamic> json) =>
      EditPhotoProfileModel(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  String? profilePhoto;

  Data({this.profilePhoto});

  factory Data.fromJson(Map<String, dynamic> json) =>
      Data(profilePhoto: json["profile_photo"]);

  Map<String, dynamic> toJson() => {"profile_photo": profilePhoto};
}
