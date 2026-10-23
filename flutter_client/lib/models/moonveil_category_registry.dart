enum MoonveilCategory {
  localMobileArchitecture,
  moonveilVttTransfer,
  moonveilUniverseInitialization,
  aiDndCharacters,
  realmsCampaignStrategy,
  moonveilVttContextRecovery,
  lovecraftianGoodGuys,
}

extension MoonveilCategoryExtension on MoonveilCategory {
  String get displayName => switch (this) {
    MoonveilCategory.localMobileArchitecture => 'Local Mobile Architecture',
    MoonveilCategory.moonveilVttTransfer => 'Moonveil VTT Transfer',
    MoonveilCategory.moonveilUniverseInitialization => 'Moonveil Universe Initialization',
    MoonveilCategory.aiDndCharacters => 'AI D&D Characters',
    MoonveilCategory.realmsCampaignStrategy => 'Realms Campaign Strategy',
    MoonveilCategory.moonveilVttContextRecovery => 'Moonveil VTT Context Recovery',
    MoonveilCategory.lovecraftianGoodGuys => 'Lovecraftian Good Guys',
  };

  String get dbKey => name;
}
