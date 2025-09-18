// To parse this JSON data, do
//
//     final getProfileModel = getProfileModelFromJson(jsonString);

import 'dart:convert';

GetProfileModel getProfileModelFromJson(String str) =>
    GetProfileModel.fromJson(json.decode(str));

String getProfileModelToJson(GetProfileModel data) =>
    json.encode(data.toJson());

class GetProfileModel {
  String? message;
  Data? data;

  GetProfileModel({this.message, this.data});

  factory GetProfileModel.fromJson(Map<String, dynamic> json) =>
      GetProfileModel(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  int? id;
  String? name;
  String? email;
  String? batchKe;
  String? trainingTitle;
  Batch? batch;
  Training? training;
  String? jenisKelamin;
  String? profilePhoto;
  String? profilePhotoUrl;

  Data({
    this.id,
    this.name,
    this.email,
    this.batchKe,
    this.trainingTitle,
    this.batch,
    this.training,
    this.jenisKelamin,
    this.profilePhoto,
    this.profilePhotoUrl,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    batchKe: json["batch_ke"],
    trainingTitle: json["training_title"],
    batch: json["batch"] == null ? null : Batch.fromJson(json["batch"]),
    training: json["training"] == null
        ? null
        : Training.fromJson(json["training"]),
    jenisKelamin: json["jenis_kelamin"],
    profilePhoto: json["profile_photo"],
    profilePhotoUrl: json["profile_photo_url"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "batch_ke": batchKe,
    "training_title": trainingTitle,
    "batch": batch?.toJson(),
    "training": training?.toJson(),
    "jenis_kelamin": jenisKelamin,
    "profile_photo": profilePhoto,
    "profile_photo_url": profilePhotoUrl,
  };
}

class Batch {
  int? id;
  String? batchKe;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? createdAt;
  DateTime? updatedAt;

  Batch({
    this.id,
    this.batchKe,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    id: json["id"],
    batchKe: json["batch_ke"],
    startDate: json["start_date"] == null
        ? null
        : DateTime.parse(json["start_date"]),
    endDate: json["end_date"] == null ? null : DateTime.parse(json["end_date"]),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "batch_ke": batchKe,
    "start_date":
        "${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
    "end_date":
        "${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}",
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class Training {
  int? id;
  String? title;
  dynamic description;
  dynamic participantCount;
  dynamic standard;
  dynamic duration;
  DateTime? createdAt;
  DateTime? updatedAt;

  Training({
    this.id,
    this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory Training.fromJson(Map<String, dynamic> json) => Training(
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
  };
}
