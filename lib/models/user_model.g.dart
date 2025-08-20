// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 4;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String?,
      watchlist: (fields[3] as List).cast<String>(),
      isDarkMode: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      lastLogin: fields[6] as DateTime,
      photoURL: fields[7] as String?,
      phoneNumber: fields[8] as String?,
      preferences: fields[9] as UserPreferences?,
      profile: fields[10] as UserProfile?,
      portfolioSymbols: (fields[11] as List).cast<String>(),
      notificationSettings: (fields[12] as Map?)?.cast<String, dynamic>(),
      lastActiveAt: fields[13] as DateTime?,
      isEmailVerified: fields[14] as bool,
      fcmToken: fields[15] as String?,
      isPremiumUser: fields[16] as bool,
      premiumExpiryDate: fields[17] as DateTime?,
      subscriptionPlan: fields[18] as String?,
      subscriptionStartDate: fields[19] as DateTime?,
      premiumFeaturesUsed: (fields[20] as List).cast<String>(),
      lastPaymentId: fields[21] as String?,
      lastUpdated: fields[23] as DateTime?,
      subscriptionCancelled: fields[22] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.watchlist)
      ..writeByte(4)
      ..write(obj.isDarkMode)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastLogin)
      ..writeByte(7)
      ..write(obj.photoURL)
      ..writeByte(8)
      ..write(obj.phoneNumber)
      ..writeByte(9)
      ..write(obj.preferences)
      ..writeByte(10)
      ..write(obj.profile)
      ..writeByte(11)
      ..write(obj.portfolioSymbols)
      ..writeByte(12)
      ..write(obj.notificationSettings)
      ..writeByte(13)
      ..write(obj.lastActiveAt)
      ..writeByte(14)
      ..write(obj.isEmailVerified)
      ..writeByte(15)
      ..write(obj.fcmToken)
      ..writeByte(16)
      ..write(obj.isPremiumUser)
      ..writeByte(17)
      ..write(obj.premiumExpiryDate)
      ..writeByte(18)
      ..write(obj.subscriptionPlan)
      ..writeByte(19)
      ..write(obj.subscriptionStartDate)
      ..writeByte(20)
      ..write(obj.premiumFeaturesUsed)
      ..writeByte(21)
      ..write(obj.lastPaymentId)
      ..writeByte(22)
      ..write(obj.subscriptionCancelled)
      ..writeByte(23)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 5;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      currency: fields[0] as String,
      language: fields[1] as String,
      timezone: fields[2] as String,
      pushNotifications: fields[3] as bool,
      emailNotifications: fields[4] as bool,
      priceAlerts: fields[5] as bool,
      newsAlerts: fields[6] as bool,
      biometricAuth: fields[7] as bool,
      alertThreshold: fields[8] as double,
      chartType: fields[9] as String,
      defaultTimeframe: fields[10] as String,
      marketOpeningAlerts: fields[11] as bool,
      portfolioSummaryAlerts: fields[12] as bool,
      preferredMarket: fields[13] as String,
      aiRecommendationAlerts: fields[14] as bool,
      lastUpdated: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.timezone)
      ..writeByte(3)
      ..write(obj.pushNotifications)
      ..writeByte(4)
      ..write(obj.emailNotifications)
      ..writeByte(5)
      ..write(obj.priceAlerts)
      ..writeByte(6)
      ..write(obj.newsAlerts)
      ..writeByte(7)
      ..write(obj.biometricAuth)
      ..writeByte(8)
      ..write(obj.alertThreshold)
      ..writeByte(9)
      ..write(obj.chartType)
      ..writeByte(10)
      ..write(obj.defaultTimeframe)
      ..writeByte(11)
      ..write(obj.marketOpeningAlerts)
      ..writeByte(12)
      ..write(obj.portfolioSummaryAlerts)
      ..writeByte(13)
      ..write(obj.preferredMarket)
      ..writeByte(14)
      ..write(obj.aiRecommendationAlerts)
      ..writeByte(15)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 6;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      bio: fields[0] as String?,
      location: fields[1] as String?,
      website: fields[2] as String?,
      dateOfBirth: fields[3] as DateTime?,
      investmentExperience: fields[4] as String?,
      riskTolerance: fields[5] as String?,
      investmentGoals: (fields[6] as List).cast<String>(),
      portfolioValue: fields[7] as double?,
      occupation: fields[8] as String?,
      socialLinks: (fields[9] as Map?)?.cast<String, dynamic>(),
      annualIncome: fields[10] as String?,
      investmentHorizon: fields[11] as String?,
      interestedSectors: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.bio)
      ..writeByte(1)
      ..write(obj.location)
      ..writeByte(2)
      ..write(obj.website)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.investmentExperience)
      ..writeByte(5)
      ..write(obj.riskTolerance)
      ..writeByte(6)
      ..write(obj.investmentGoals)
      ..writeByte(7)
      ..write(obj.portfolioValue)
      ..writeByte(8)
      ..write(obj.occupation)
      ..writeByte(9)
      ..write(obj.socialLinks)
      ..writeByte(10)
      ..write(obj.annualIncome)
      ..writeByte(11)
      ..write(obj.investmentHorizon)
      ..writeByte(12)
      ..write(obj.interestedSectors);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
