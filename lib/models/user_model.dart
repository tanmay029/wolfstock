// lib/models/user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 4)
class UserModel extends HiveObject {
  @HiveField(0)
  String uid;
  
  @HiveField(1)
  String email;
  
  @HiveField(2)
  String? displayName;
  
  @HiveField(3)
  List<String> watchlist;
  
  @HiveField(4)
  bool isDarkMode;
  
  @HiveField(5)
  DateTime createdAt;
  
  @HiveField(6)
  DateTime lastLogin;
  
  @HiveField(7)
  String? photoURL;
  
  @HiveField(8)
  String? phoneNumber;
  
  @HiveField(9)
  UserPreferences preferences;
  
  @HiveField(10)
  UserProfile profile;
  
  @HiveField(11)
  List<String> portfolioSymbols;
  
  @HiveField(12)
  Map<String, dynamic>? notificationSettings;
  
  @HiveField(13)
  DateTime? lastActiveAt;
  
  @HiveField(14)
  bool isEmailVerified;
  
  @HiveField(15)
  String? fcmToken; 

  @HiveField(16)
  bool isPremiumUser;

  @HiveField(17)
  DateTime? premiumExpiryDate;

  @HiveField(18)
  String? subscriptionPlan; 

  @HiveField(19)
  DateTime? subscriptionStartDate;

  @HiveField(20)
  List<String> premiumFeaturesUsed;

  @HiveField(21) 
  String? lastPaymentId;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.watchlist = const [],
    this.isDarkMode = false,
    required this.createdAt,
    required this.lastLogin,
    this.photoURL,
    this.phoneNumber,
    UserPreferences? preferences,
    UserProfile? profile,
    this.portfolioSymbols = const [],
    this.notificationSettings,
    this.lastActiveAt,
    this.isEmailVerified = false,
    this.fcmToken,
    this.isPremiumUser = false,
    this.premiumExpiryDate,
    this.subscriptionPlan,
    this.subscriptionStartDate,
    this.premiumFeaturesUsed = const [],
    this.lastPaymentId,
  }) : preferences = preferences ?? UserPreferences(),
       profile = profile ?? UserProfile();

  bool get hasActivePremium {
  if (!isPremiumUser) return false;
  if (subscriptionPlan == 'lifetime') return true;
  if (premiumExpiryDate == null) return false;
  return DateTime.now().isBefore(premiumExpiryDate!);
}

int get daysUntilPremiumExpiry {
  if (!hasActivePremium) return 0;
  if (subscriptionPlan == 'lifetime') return 999999;
  return premiumExpiryDate!.difference(DateTime.now()).inDays;
}

bool get isPremiumExpiringSoon => daysUntilPremiumExpiry <= 7 && daysUntilPremiumExpiry > 0;


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      isPremiumUser: json['isPremiumUser'] ?? false,
    premiumExpiryDate: json['premiumExpiryDate'] != null 
        ? DateTime.parse(json['premiumExpiryDate']) 
        : null,
    subscriptionPlan: json['subscriptionPlan'],
    subscriptionStartDate: json['subscriptionStartDate'] != null 
        ? DateTime.parse(json['subscriptionStartDate']) 
        : null,
    premiumFeaturesUsed: List<String>.from(json['premiumFeaturesUsed'] ?? []),
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      watchlist: List<String>.from(json['watchlist'] ?? []),
      isDarkMode: json['isDarkMode'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : DateTime.now(),
      photoURL: json['photoURL'],
      phoneNumber: json['phoneNumber'],
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : UserPreferences(),
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : UserProfile(),
      portfolioSymbols: List<String>.from(json['portfolioSymbols'] ?? []),
      notificationSettings: json['notificationSettings'],
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt']) 
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'watchlist': watchlist,
      'isDarkMode': isDarkMode,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'preferences': preferences.toJson(),
      'profile': profile.toJson(),
      'portfolioSymbols': portfolioSymbols,
      'notificationSettings': notificationSettings,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'fcmToken': fcmToken,
      'isPremiumUser': isPremiumUser,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'premiumFeaturesUsed': premiumFeaturesUsed,
      'lastPaymentId': lastPaymentId,
    };
  }

  // Utility methods
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      List<String> nameParts = displayName!.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  String get firstName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!.split(' ').first;
    }
    return email.split('@').first;
  }

  String get lastName {
    if (displayName != null && displayName!.isNotEmpty) {
      List<String> parts = displayName!.split(' ');
      return parts.length > 1 ? parts.last : '';
    }
    return '';
  }

  bool get hasWatchlist => watchlist.isNotEmpty;
  bool get hasPortfolio => portfolioSymbols.isNotEmpty;
  bool get isActive => lastActiveAt != null && 
      DateTime.now().difference(lastActiveAt!).inDays < 7;

  // Watchlist methods
  bool isInWatchlist(String symbol) => watchlist.contains(symbol.toUpperCase());
  
  void addToWatchlist(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    if (!watchlist.contains(upperSymbol)) {
      watchlist.add(upperSymbol);
    }
  }

  void removeFromWatchlist(String symbol) {
    watchlist.remove(symbol.toUpperCase());
  }

  // Portfolio methods
  bool isInPortfolio(String symbol) => portfolioSymbols.contains(symbol.toUpperCase());
  
  void addToPortfolio(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    if (!portfolioSymbols.contains(upperSymbol)) {
      portfolioSymbols.add(upperSymbol);
    }
  }

  void removeFromPortfolio(String symbol) {
    portfolioSymbols.remove(symbol.toUpperCase());
  }

  // Update methods
  void updateLastActive() {
    lastActiveAt = DateTime.now();
  }

  void updateLastLogin() {
    lastLogin = DateTime.now();
    updateLastActive();
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    List<String>? watchlist,
    bool? isDarkMode,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? photoURL,
    String? phoneNumber,
    UserPreferences? preferences,
    UserProfile? profile,
    List<String>? portfolioSymbols,
    Map<String, dynamic>? notificationSettings,
    DateTime? lastActiveAt,
    bool? isEmailVerified,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      watchlist: watchlist ?? this.watchlist,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
      profile: profile ?? this.profile,
      portfolioSymbols: portfolioSymbols ?? this.portfolioSymbols,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel{uid: $uid, email: $email, displayName: $displayName}';
  }
}

@HiveType(typeId: 5)
class UserPreferences extends HiveObject {
  @HiveField(0)
  String currency;
  
  @HiveField(1)
  String language;
  
  @HiveField(2)
  String timezone;
  
  @HiveField(3)
  bool pushNotifications;
  
  @HiveField(4)
  bool emailNotifications;
  
  @HiveField(5)
  bool priceAlerts;
  
  @HiveField(6)
  bool newsAlerts;
  
  @HiveField(7)
  bool biometricAuth;
  
  @HiveField(8)
  double alertThreshold; // Percentage change threshold for alerts
  
  @HiveField(9)
  String chartType; // 'line', 'candle', etc.
  
  @HiveField(10)
  String defaultTimeframe; // '1D', '1W', '1M', etc.

  UserPreferences({
    this.currency = 'USD',
    this.language = 'en',
    this.timezone = 'UTC',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.priceAlerts = true,
    this.newsAlerts = false,
    this.biometricAuth = false,
    this.alertThreshold = 5.0,
    this.chartType = 'line',
    this.defaultTimeframe = '1D',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      currency: json['currency'] ?? 'USD',
      language: json['language'] ?? 'en',
      timezone: json['timezone'] ?? 'UTC',
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      priceAlerts: json['priceAlerts'] ?? true,
      newsAlerts: json['newsAlerts'] ?? false,
      biometricAuth: json['biometricAuth'] ?? false,
      alertThreshold: (json['alertThreshold'] ?? 5.0).toDouble(),
      chartType: json['chartType'] ?? 'line',
      defaultTimeframe: json['defaultTimeframe'] ?? '1D',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'language': language,
      'timezone': timezone,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'priceAlerts': priceAlerts,
      'newsAlerts': newsAlerts,
      'biometricAuth': biometricAuth,
      'alertThreshold': alertThreshold,
      'chartType': chartType,
      'defaultTimeframe': defaultTimeframe,
    };
  }
}

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? bio;
  
  @HiveField(1)
  String? location;
  
  @HiveField(2)
  String? website;
  
  @HiveField(3)
  DateTime? dateOfBirth;
  
  @HiveField(4)
  String? investmentExperience; // 'Beginner', 'Intermediate', 'Advanced'
  
  @HiveField(5)
  String? riskTolerance; // 'Low', 'Medium', 'High'
  
  @HiveField(6)
  List<String> investmentGoals;
  
  @HiveField(7)
  double? portfolioValue;
  
  @HiveField(8)
  String? occupation;
  
  @HiveField(9)
  Map<String, dynamic>? socialLinks;

  UserProfile({
    this.bio,
    this.location,
    this.website,
    this.dateOfBirth,
    this.investmentExperience = 'Beginner',
    this.riskTolerance = 'Medium',
    this.investmentGoals = const [],
    this.portfolioValue,
    this.occupation,
    this.socialLinks,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio'],
      location: json['location'],
      website: json['website'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      investmentExperience: json['investmentExperience'] ?? 'Beginner',
      riskTolerance: json['riskTolerance'] ?? 'Medium',
      investmentGoals: List<String>.from(json['investmentGoals'] ?? []),
      portfolioValue: json['portfolioValue']?.toDouble(),
      occupation: json['occupation'],
      socialLinks: json['socialLinks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'location': location,
      'website': website,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'investmentExperience': investmentExperience,
      'riskTolerance': riskTolerance,
      'investmentGoals': investmentGoals,
      'portfolioValue': portfolioValue,
      'occupation': occupation,
      'socialLinks': socialLinks,
    };
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isProfileComplete {
    return bio != null &&
           location != null &&
           investmentExperience != null &&
           riskTolerance != null &&
           investmentGoals.isNotEmpty;
  }
}
