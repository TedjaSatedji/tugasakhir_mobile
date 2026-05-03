import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_item_model.dart';
import '../models/character_model.dart';
import 'character_provider.dart';

/// Manages shop state by reading/writing directly to [CharacterModel],
/// which is persisted locally and synced to the cloud via [SyncService].
///
/// Game upgrades  → character.shopUpgrades (GameUpgrades JSON)
/// Owned frames   → character.ownedFrames   (List<String>)
/// Coins          → character.coins         (int)
///
/// Equipped frame is a local preference only (SharedPreferences).
class ShopProvider extends ChangeNotifier {
  static const _equippedFrameKey = 'equipped_frame_id';

  CharacterProvider? _charProvider;
  String _equippedFrameId = 'frame_neon';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String get equippedFrameId => _equippedFrameId;
  AvatarFrame get equippedFrame => AvatarFrame.byId(_equippedFrameId);

  // ── Derived from CharacterModel ────────────────────────────────────────────

  GameUpgrades get upgrades =>
      _charProvider?.character?.shopUpgrades ?? const GameUpgrades();

  List<String> get purchasedFrameIds {
    final base = _charProvider?.character?.ownedFrames ?? const ['frame_neon'];
    // Always include frame_neon (free default)
    return base.contains('frame_neon') ? base : ['frame_neon', ...base];
  }

  bool isFrameOwned(String frameId) =>
      frameId == 'frame_neon' || purchasedFrameIds.contains(frameId);

  ShopProvider() {
    _loadEquippedFrame();
  }

  Future<void> _loadEquippedFrame() async {
    final prefs = await SharedPreferences.getInstance();
    _equippedFrameId = prefs.getString(_equippedFrameKey) ?? 'frame_neon';
    // Guard: ensure the equipped frame is still owned
    notifyListeners();
  }

  /// Call this after CharacterProvider is available (e.g. from main.dart or a ProxyProvider).
  /// ShopProvider watches CharacterProvider for changes.
  void attachCharacterProvider(CharacterProvider charProvider) {
    if (_charProvider == charProvider) return;
    _charProvider?.removeListener(_onCharacterChanged);
    _charProvider = charProvider;
    _charProvider!.addListener(_onCharacterChanged);
    _onCharacterChanged();
  }

  void _onCharacterChanged() {
    // If equipped frame is no longer owned (e.g. after server reset), fall back
    if (!isFrameOwned(_equippedFrameId)) {
      _equippedFrameId = 'frame_neon';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _charProvider?.removeListener(_onCharacterChanged);
    super.dispose();
  }

  // ── Game Upgrades ──────────────────────────────────────────────────────────

  /// Returns true if purchase succeeded, false if insufficient coins or max level.
  Future<bool> purchaseUpgrade(
    CharacterProvider charProvider,
    UpgradeType type,
  ) async {
    final def = UpgradeDef.byType(type);
    final currentLevel = upgrades.currentLevel(type);
    if (currentLevel >= def.maxLevel) return false;

    final cost = def.costsPerLevel[currentLevel];
    final spent = charProvider.spendCoins(cost);
    if (!spent) return false;

    // Build updated upgrades
    GameUpgrades updated;
    switch (type) {
      case UpgradeType.fasterShip:
        updated = upgrades.copyWith(fasterShipLevel: currentLevel + 1);
        break;
      case UpgradeType.extraLives:
        updated = upgrades.copyWith(extraLivesLevel: currentLevel + 1);
        break;
      case UpgradeType.fasterBullets:
        updated = upgrades.copyWith(fasterBulletsLevel: currentLevel + 1);
        break;
    }

    await charProvider.updateShopUpgrades(updated);
    notifyListeners();
    return true;
  }

  // ── Avatar Frames ──────────────────────────────────────────────────────────

  /// Returns true if purchase succeeded, false if insufficient coins or already owned.
  Future<bool> purchaseFrame(
    CharacterProvider charProvider,
    String frameId,
  ) async {
    if (isFrameOwned(frameId)) return false;
    final frame = AvatarFrame.byId(frameId);
    final spent = charProvider.spendCoins(frame.cost);
    if (!spent) return false;

    final newOwned = [...purchasedFrameIds, frameId];
    await charProvider.updateOwnedFrames(newOwned);
    notifyListeners();
    return true;
  }

  Future<void> equipFrame(String frameId) async {
    if (!isFrameOwned(frameId)) return;
    _equippedFrameId = frameId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedFrameKey, frameId);
    notifyListeners();
  }
}
