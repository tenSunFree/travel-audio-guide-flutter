enum AttractionSortOrder {
  apiOrder,
  distanceAsc,
  nameAZ,
  modifiedNewest;

  String get label => switch (this) {
    AttractionSortOrder.apiOrder => '預設（API 順序）',
    AttractionSortOrder.distanceAsc => '距離近→遠（需開啟定位）',
    AttractionSortOrder.nameAZ => '名稱 A-Z',
    AttractionSortOrder.modifiedNewest => '最近更新',
  };
}

enum AttractionTimeSlotFilter {
  all,
  morning,
  afternoon,
  evening,
  night;

  String get label => switch (this) {
    AttractionTimeSlotFilter.all => '全部',
    AttractionTimeSlotFilter.morning => '早上推薦',
    AttractionTimeSlotFilter.afternoon => '下午推薦',
    AttractionTimeSlotFilter.evening => '傍晚推薦',
    AttractionTimeSlotFilter.night => '夜間推薦',
  };

  String get queryValue => switch (this) {
    AttractionTimeSlotFilter.all => 'all',
    AttractionTimeSlotFilter.morning => 'morning',
    AttractionTimeSlotFilter.afternoon => 'afternoon',
    AttractionTimeSlotFilter.evening => 'evening',
    AttractionTimeSlotFilter.night => 'night',
  };

  /// Convert the query param string back to an enum (if not found, return all).
  static AttractionTimeSlotFilter fromQuery(String? value) {
    return switch (value) {
      'morning' => AttractionTimeSlotFilter.morning,
      'afternoon' => AttractionTimeSlotFilter.afternoon,
      'evening' => AttractionTimeSlotFilter.evening,
      'night' => AttractionTimeSlotFilter.night,
      _ => AttractionTimeSlotFilter.all,
    };
  }
}

// Suitable groups (corresponding to the id of API target[])
enum AttractionTargetFilter {
  hiker(66, '健行族'),
  familyLearning(61, '親子共學'),
  fieldTrip(62, '校外教學'),
  cyclist(63, '單車族'),
  birdWatcher(65, '賞鳥族');

  const AttractionTargetFilter(this.apiId, this.label);

  final int apiId;
  final String label;
}

// Friendly Facilities (corresponding to the id of API friendly[])
enum AttractionFacilityFilter {
  accessible(392, '♿ 無障礙'),
  wifi(398, '📶 WiFi'),
  easyCard(394, '💳 悠遊卡'),
  pet(391, '🐾 寵物'),
  vegetarian(395, '🍽️ 素食'),
  toilet(396, '🚽 友善廁所'),
  nursing(400, '👶 哺乳室'),
  charging(390, '🔋 充電');

  const AttractionFacilityFilter(this.apiId, this.label);

  final int apiId;
  final String label;
}
