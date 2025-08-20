// lib/models/user_model.dart (Enhanced & Refactored)
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

  @HiveField(22)
  bool? subscriptionCancelled;

  @HiveField(23)
  DateTime? lastUpdated;


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
    this.lastUpdated,
    this.subscriptionCancelled = false,
  }) : preferences = preferences ?? UserPreferences(),
       profile = profile ?? UserProfile();

  // === PREMIUM STATUS GETTERS ===
  bool get hasActivePremium {
    if (!isPremiumUser) return false;
    if (subscriptionPlan == 'lifetime') return true;
    if (premiumExpiryDate == null) return false;
    if (subscriptionCancelled == true) {
      // Allow access until expiry even if cancelled
      return DateTime.now().isBefore(premiumExpiryDate!);
    }
    return DateTime.now().isBefore(premiumExpiryDate!);
  }

  int get daysUntilPremiumExpiry {
    if (!hasActivePremium) return 0;
    if (subscriptionPlan == 'lifetime') return 999999;
    return premiumExpiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isPremiumExpiringSoon => daysUntilPremiumExpiry <= 7 && daysUntilPremiumExpiry > 0;

  String get premiumStatusLabel {
    if (subscriptionPlan == 'lifetime') return 'Lifetime Premium';
    if (hasActivePremium) {
      if (subscriptionCancelled == true) {
        return 'Cancelled (Active until ${premiumExpiryDate?.toString().split(' ')[0]})';
      }
      return 'Active ($daysUntilPremiumExpiry days remaining)';
    }
    if (isPremiumExpiringSoon) return 'Expiring Soon';
    return 'Inactive';
  }

  // === PROFILE & PREFERENCES SAFE GETTERS ===
  String get riskTolerance => profile.riskTolerance ?? 'Medium';
  String get investmentExperience => profile.investmentExperience ?? 'Beginner';
  List<String> get investmentGoals => profile.investmentGoals;
  double get portfolioValue => profile.portfolioValue ?? 0.0;

  // === PROFILE COMPLETION ===
  int get profileCompletion {
    int completed = 0;
    int total = 6;
    
    if (profile.bio != null && profile.bio!.trim().isNotEmpty) completed++;
    if (profile.location != null && profile.location!.trim().isNotEmpty) completed++;
    if (profile.investmentExperience != null) completed++;
    if (profile.riskTolerance != null) completed++;
    if (profile.investmentGoals.isNotEmpty) completed++;
    if (displayName != null && displayName!.trim().isNotEmpty) completed++;
    
    return ((completed / total) * 100).round();
  }

  bool get isProfileComplete => profileCompletion >= 80;

  // === UTILITY GETTERS ===
  String get initials {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      List<String> nameParts = displayName!.trim().split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1]}'.toUpperCase();
      }
      return displayName!.toUpperCase();
    }
    return email.toUpperCase();
  }

  String get firstName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim().split(' ').first;
    }
    return email.split('@').first;
  }

  String get lastName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      List<String> parts = displayName!.trim().split(' ');
      return parts.length > 1 ? parts.last : '';
    }
    return '';
  }

  String get fullName => displayName?.trim() ?? firstName;

  bool get hasWatchlist => watchlist.isNotEmpty;
  bool get hasPortfolio => portfolioSymbols.isNotEmpty;
  bool get isActive => lastActiveAt != null && 
      DateTime.now().difference(lastActiveAt!).inDays < 7;

  String get membershipDuration {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inDays < 30) {
      return '${duration.inDays} days';
    } else if (duration.inDays < 365) {
      return '${(duration.inDays / 30).floor()} months';
    } else {
      return '${(duration.inDays / 365).floor()} years';
    }
  }

  // === ENHANCED WATCHLIST METHODS ===
  bool isInWatchlist(String symbol) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    return watchlist.any((s) => s.toUpperCase() == normalizedSymbol);
  }
  
  void addToWatchlist(String symbol) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    if (!isInWatchlist(normalizedSymbol)) {
      watchlist.add(normalizedSymbol);
    }
  }

  void removeFromWatchlist(String symbol) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    watchlist.removeWhere((s) => s.toUpperCase() == normalizedSymbol);
  }

  void clearWatchlist() {
    watchlist.clear();
  }

  // === ENHANCED PORTFOLIO METHODS ===
  bool isInPortfolio(String symbol) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    return portfolioSymbols.any((s) => s.toUpperCase() == normalizedSymbol);
  }
  
  void addToPortfolio(String symbol) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    if (!isInPortfolio(normalizedSymbol)) {
      portfolioSymbols.add(normalizedSymbol);
    }
  }

  void removeFromPortfolio(String symbol) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    portfolioSymbols.removeWhere((s) => s.toUpperCase() == normalizedSymbol);
  }

  void clearPortfolio() {
    portfolioSymbols.clear();
  }

  // === UPDATE METHODS ===
  void updateLastActive() {
    lastActiveAt = DateTime.now();
  }

  void updateLastLogin() {
    lastLogin = DateTime.now();
    updateLastActive();
  }

  void updatePreference(String key, dynamic value) {
    final prefsMap = preferences.toJson();
    prefsMap[key] = value;
    preferences = UserPreferences.fromJson(prefsMap);
  }

  void updateProfile(String key, dynamic value) {
    final profileMap = profile.toJson();
    profileMap[key] = value;
    profile = UserProfile.fromJson(profileMap);
  }

  void updateNotificationSetting(String key, dynamic value) {
    notificationSettings ??= {};
    notificationSettings![key] = value;
  }

  // === SERIALIZATION ===
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName']?.toString().trim(),
      watchlist: List<String>.from(json['watchlist'] ?? [])
          .map((s) => s.toString().trim().toUpperCase())
          .where((s) => s.isNotEmpty)
          .toList(),
      isDarkMode: json['isDarkMode'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : DateTime.now(),
      photoURL: json['photoURL']?.toString().trim(),
      phoneNumber: json['phoneNumber']?.toString().trim(),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(Map<String, dynamic>.from(json['preferences']))
          : UserPreferences(),
      profile: json['profile'] != null
          ? UserProfile.fromJson(Map<String, dynamic>.from(json['profile']))
          : UserProfile(),
      portfolioSymbols: List<String>.from(json['portfolioSymbols'] ?? [])
          .map((s) => s.toString().trim().toUpperCase())
          .where((s) => s.isNotEmpty)
          .toList(),
      notificationSettings: json['notificationSettings'] != null
          ? Map<String, dynamic>.from(json['notificationSettings'])
          : null,
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt']) 
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      fcmToken: json['fcmToken']?.toString().trim(),
      isPremiumUser: json['isPremiumUser'] ?? false,
      premiumExpiryDate: json['premiumExpiryDate'] != null 
          ? DateTime.parse(json['premiumExpiryDate']) 
          : null,
      subscriptionPlan: json['subscriptionPlan']?.toString().trim(),
      subscriptionStartDate: json['subscriptionStartDate'] != null 
          ? DateTime.parse(json['subscriptionStartDate']) 
          : null,
      premiumFeaturesUsed: List<String>.from(json['premiumFeaturesUsed'] ?? []),
      lastPaymentId: json['lastPaymentId']?.toString().trim(),
      subscriptionCancelled: json['subscriptionCancelled'] ?? false,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
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
      'subscriptionCancelled': subscriptionCancelled,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
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
    bool? isPremiumUser,
    DateTime? premiumExpiryDate,
    String? subscriptionPlan,
    DateTime? subscriptionStartDate,
    List<String>? premiumFeaturesUsed,
    String? lastPaymentId,
    bool? subscriptionCancelled,
    DateTime? lastUpdated,
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
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      premiumFeaturesUsed: premiumFeaturesUsed ?? this.premiumFeaturesUsed,
      lastPaymentId: lastPaymentId ?? this.lastPaymentId,
      subscriptionCancelled: subscriptionCancelled ?? this.subscriptionCancelled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
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
    return 'UserModel{uid: $uid, email: $email, displayName: $displayName, isPremium: $hasActivePremium}';
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
  double alertThreshold;
  
  @HiveField(9)
  String chartType;
  
  @HiveField(10)
  String defaultTimeframe;

  @HiveField(11)
  bool marketOpeningAlerts;

  @HiveField(12)
  bool portfolioSummaryAlerts;

  @HiveField(13)
  String preferredMarket; // 'US', 'IN', 'Global'

  @HiveField(14)
  bool aiRecommendationAlerts;

  @HiveField(15)
  DateTime? lastUpdated;

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
    this.marketOpeningAlerts = false,
    this.portfolioSummaryAlerts = true,
    this.preferredMarket = 'US',
    this.aiRecommendationAlerts = true,
    this.lastUpdated,
  });

  // === HELPER GETTERS ===
  bool get hasAnyNotifications => 
      pushNotifications || emailNotifications || priceAlerts || newsAlerts;

  String get currencySymbol {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'INR': return '₹';
      case 'JPY': return '¥';
      default: return '\$';
    }
  }

  // === UPDATE METHODS ===
  void updateNotificationSettings({
    bool? push,
    bool? email,
    bool? price,
    bool? news,
    bool? marketOpening,
    bool? portfolioSummary,
    bool? aiRecommendation,
  }) {
    if (push != null) pushNotifications = push;
    if (email != null) emailNotifications = email;
    if (price != null) priceAlerts = price;
    if (news != null) newsAlerts = news;
    if (marketOpening != null) marketOpeningAlerts = marketOpening;
    if (portfolioSummary != null) portfolioSummaryAlerts = portfolioSummary;
    if (aiRecommendation != null) aiRecommendationAlerts = aiRecommendation;
  }

  void disableAllNotifications() {
    pushNotifications = false;
    emailNotifications = false;
    priceAlerts = false;
    newsAlerts = false;
    marketOpeningAlerts = false;
    portfolioSummaryAlerts = false;
    aiRecommendationAlerts = false;
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      currency: json['currency']?.toString() ?? 'USD',
      language: json['language']?.toString() ?? 'en',
      timezone: json['timezone']?.toString() ?? 'UTC',
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      priceAlerts: json['priceAlerts'] ?? true,
      newsAlerts: json['newsAlerts'] ?? false,
      biometricAuth: json['biometricAuth'] ?? false,
      alertThreshold: (json['alertThreshold'] ?? 5.0).toDouble(),
      chartType: json['chartType']?.toString() ?? 'line',
      defaultTimeframe: json['defaultTimeframe']?.toString() ?? '1D',
      marketOpeningAlerts: json['marketOpeningAlerts'] ?? false,
      portfolioSummaryAlerts: json['portfolioSummaryAlerts'] ?? true,
      preferredMarket: json['preferredMarket']?.toString() ?? 'US',
      aiRecommendationAlerts: json['aiRecommendationAlerts'] ?? true,
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
      'marketOpeningAlerts': marketOpeningAlerts,
      'portfolioSummaryAlerts': portfolioSummaryAlerts,
      'preferredMarket': preferredMarket,
      'aiRecommendationAlerts': aiRecommendationAlerts,
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
  String? investmentExperience;
  
  @HiveField(5)
  String? riskTolerance;
  
  @HiveField(6)
  List<String> investmentGoals;
  
  @HiveField(7)
  double? portfolioValue;
  
  @HiveField(8)
  String? occupation;
  
  @HiveField(9)
  Map<String, dynamic>? socialLinks;

  @HiveField(10)
  String? annualIncome;

  @HiveField(11)
  String? investmentHorizon; // 'Short', 'Medium', 'Long'

  @HiveField(12)
  List<String> interestedSectors;

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
    this.annualIncome,
    this.investmentHorizon = 'Medium',
    this.interestedSectors = const [],
  });

  // === COMPUTED PROPERTIES ===
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

  String get ageGroup {
    final userAge = age;
    if (userAge == null) return 'Unknown';
    if (userAge < 25) return 'Young Adult';
    if (userAge < 40) return 'Adult';
    if (userAge < 60) return 'Middle-aged';
    return 'Senior';
  }

  bool get isProfileComplete {
    int requiredFields = 0;
    int completedFields = 0;
    
    // Required fields for complete profile
    requiredFields = 6;
    
    if (bio != null && bio!.trim().isNotEmpty) completedFields++;
    if (location != null && location!.trim().isNotEmpty) completedFields++;
    if (investmentExperience != null) completedFields++;
    if (riskTolerance != null) completedFields++;
    if (investmentGoals.isNotEmpty) completedFields++;
    if (occupation != null && occupation!.trim().isNotEmpty) completedFields++;
    
    return completedFields >= (requiredFields * 0.8); // 80% completion
  }

  double get completionPercentage {
    int totalFields = 8; // Total possible fields
    int completedFields = 0;
    
    if (bio != null && bio!.trim().isNotEmpty) completedFields++;
    if (location != null && location!.trim().isNotEmpty) completedFields++;
    if (dateOfBirth != null) completedFields++;
    if (investmentExperience != null) completedFields++;
    if (riskTolerance != null) completedFields++;
    if (investmentGoals.isNotEmpty) completedFields++;
    if (occupation != null && occupation!.trim().isNotEmpty) completedFields++;
    if (portfolioValue != null && portfolioValue! > 0) completedFields++;
    
    return (completedFields / totalFields) * 100;
  }

  // === INVESTMENT PROFILE HELPERS ===
  bool get isConservativeInvestor => 
      riskTolerance?.toLowerCase() == 'low' || 
      (age != null && age! > 50);

  bool get isAggressiveInvestor => 
      riskTolerance?.toLowerCase() == 'high' && 
      (age == null || age! < 35);

  String get investorType {
    if (isConservativeInvestor) return 'Conservative';
    if (isAggressiveInvestor) return 'Aggressive';
    return 'Moderate';
  }

  List<String> get recommendedAssetClasses {
    switch (riskTolerance?.toLowerCase()) {
      case 'low':
        return ['Bonds', 'Blue-chip Stocks', 'REITs', 'Fixed Deposits'];
      case 'high':
        return ['Growth Stocks', 'Tech Stocks', 'Crypto', 'Options'];
      default:
        return ['Index Funds', 'Large-cap Stocks', 'Balanced Funds', 'ETFs'];
    }
  }

  // === UPDATE METHODS ===
  void updateInvestmentProfile({
    String? experience,
    String? risk,
    List<String>? goals,
    double? portfolioVal,
    String? horizon,
    List<String>? sectors,
  }) {
    if (experience != null) investmentExperience = experience;
    if (risk != null) riskTolerance = risk;
    if (goals != null) investmentGoals = goals;
    if (portfolioVal != null) portfolioValue = portfolioVal;
    if (horizon != null) investmentHorizon = horizon;
    if (sectors != null) interestedSectors = sectors;
  }

  void addInvestmentGoal(String goal) {
    if (!investmentGoals.contains(goal)) {
      investmentGoals.add(goal);
    }
  }

  void removeInvestmentGoal(String goal) {
    investmentGoals.remove(goal);
  }

  void addInterestedSector(String sector) {
    if (!interestedSectors.contains(sector)) {
      interestedSectors.add(sector);
    }
  }

  void removeInterestedSector(String sector) {
    interestedSectors.remove(sector);
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio']?.toString().trim(),
      location: json['location']?.toString().trim(),
      website: json['website']?.toString().trim(),
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      investmentExperience: json['investmentExperience']?.toString() ?? 'Beginner',
      riskTolerance: json['riskTolerance']?.toString() ?? 'Medium',
      investmentGoals: List<String>.from(json['investmentGoals'] ?? []),
      portfolioValue: json['portfolioValue']?.toDouble(),
      occupation: json['occupation']?.toString().trim(),
      socialLinks: json['socialLinks'] != null
          ? Map<String, dynamic>.from(json['socialLinks'])
          : null,
      annualIncome: json['annualIncome']?.toString(),
      investmentHorizon: json['investmentHorizon']?.toString() ?? 'Medium',
      interestedSectors: List<String>.from(json['interestedSectors'] ?? []),
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
      'annualIncome': annualIncome,
      'investmentHorizon': investmentHorizon,
      'interestedSectors': interestedSectors,
    };
  }
}
