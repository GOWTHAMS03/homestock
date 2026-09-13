import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/shopping/shopping_model.dart';
import 'package:homestock/features/voice/models/voice_models.dart';
import 'package:homestock/features/voice/providers/voice_command_provider.dart';
import 'package:homestock/features/voice/services/voice_ai_service.dart';

class FakeShoppingController extends StateNotifier<ShoppingState> implements ShoppingController {
  final List<Map<String, dynamic>> addedItems = [];
  final List<String> deletedItemIds = [];
  bool clearedCompletedCalled = false;

  FakeShoppingController() : super(const ShoppingState());

  @override
  Future<bool> addItem({
    String? inventoryItemId,
    required String itemName,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required double quantity,
    String unit = 'pcs',
    String? notes,
  }) async {
    addedItems.add({
      'inventoryItemId': inventoryItemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'categoryName': categoryName,
    });
    return true;
  }

  @override
  Future<void> deleteItem(String itemId) async {
    deletedItemIds.add(itemId);
  }

  @override
  Future<void> clearCompleted() async {
    clearedCompletedCalled = true;
  }

  @override
  Future<void> loadShoppingList({bool forceRemote = false}) async {}

  @override
  Future<void> markItemsCompleted(List<String> itemIds) async {}

  @override
  Future<void> toggleItem(String itemId) async {}

  @override
  Future<void> updateQuantity(String itemId, double newQuantity) async {}
}

class FakeHomeController extends StateNotifier<HomeState> implements HomeController {
  FakeHomeController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeShoppingController fakeShoppingController;

  setUp(() {
    fakeShoppingController = FakeShoppingController();
  });

  test('Homie Voice adds item to shopping list using direct shopping controller connection', () async {
    final fakeHome = HomeModel(
      id: 'home-123',
      name: 'My Sweet Home',
      inviteCode: 'ABCDEF',
      currentUserRole: 'OWNER',
      memberCount: 1,
    );

    final container = ProviderContainer(
      overrides: [
        shoppingControllerProvider.overrideWith((ref) => fakeShoppingController),
        voiceAiServiceProvider.overrideWithValue(
          VoiceAiService(
            voiceRepository: null,
            localExecutor: null,
            isOnline: true,
          ),
        ),
        homeControllerProvider.overrideWith(
          (ref) => FakeHomeController(
            HomeState(activeHome: fakeHome, homes: [fakeHome]),
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    final voiceController = container.read(voiceAiControllerProvider.notifier);

    // Simulate Homie receiving command: "2 kilo rice shopping list la add pannu"
    final commandResult = const VoiceCommandResult(
      transcript: '2 kilo rice shopping list la add pannu',
      intent: VoiceIntentType.addShoppingItem,
      confidence: 0.95,
      intentConfidence: 0.95,
      productMatchConfidence: 0.95,
      message: '2 kilo Rice shopping list-la add panniten.',
      entities: VoiceEntities(
        itemName: 'Rice',
        quantity: 2.0,
        unit: 'kg',
      ),
      detectedLanguage: 'TANGLISH',
    );

    voiceController.state = voiceController.state.copyWith(
      status: VoiceAiStatus.confirming,
      commandResult: commandResult,
    );

    // Execute Homie command
    await voiceController.executeCommand();

    // Verify Homie succeeded
    final state = container.read(voiceAiControllerProvider);
    expect(state.status, VoiceAiStatus.success);
    expect(state.executionResponse?.success, true);
    expect(state.executionResponse?.message, contains('Rice'));
    expect(state.executionResponse?.message, contains('2 kg'));

    // Verify item was directly forwarded to ShoppingController
    expect(fakeShoppingController.addedItems.length, 1);
    expect(fakeShoppingController.addedItems.first['itemName'], 'Rice');
    expect(fakeShoppingController.addedItems.first['quantity'], 2.0);
    expect(fakeShoppingController.addedItems.first['unit'], 'kg');
  });

  test('Homie defaults quantity to 1.0 when user says "shopping list la sugar add pannu" without quantity', () async {
    final fakeHome = HomeModel(
      id: 'home-123',
      name: 'My Sweet Home',
      inviteCode: 'ABCDEF',
      currentUserRole: 'OWNER',
      memberCount: 1,
    );

    final container = ProviderContainer(
      overrides: [
        shoppingControllerProvider.overrideWith((ref) => fakeShoppingController),
        voiceAiServiceProvider.overrideWithValue(
          VoiceAiService(
            voiceRepository: null,
            localExecutor: null,
            isOnline: true,
          ),
        ),
        homeControllerProvider.overrideWith(
          (ref) => FakeHomeController(
            HomeState(activeHome: fakeHome, homes: [fakeHome]),
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    final voiceController = container.read(voiceAiControllerProvider.notifier);

    // Simulate Homie receiving command without quantity: "shopping list la sugar add pannu"
    final commandResult = const VoiceCommandResult(
      transcript: 'shopping list la sugar add pannu',
      intent: VoiceIntentType.addShoppingItem,
      confidence: 0.95,
      intentConfidence: 0.95,
      productMatchConfidence: 0.95,
      message: 'Added sugar to shopping list',
      entities: VoiceEntities(
        itemName: 'Sugar',
        quantity: null,
        unit: null,
      ),
      detectedLanguage: 'TANGLISH',
    );

    voiceController.state = voiceController.state.copyWith(
      status: VoiceAiStatus.confirming,
      commandResult: commandResult,
    );

    // Execute Homie command
    await voiceController.executeCommand();

    // Verify Homie defaulted quantity to 1 pcs and succeeded
    final state = container.read(voiceAiControllerProvider);
    expect(state.status, VoiceAiStatus.success);
    expect(state.executionResponse?.success, true);
    expect(state.executionResponse?.message, contains('Added 1 pcs Sugar to shopping list!'));

    // Verify item in ShoppingController has quantity 1.0 and unit pcs
    expect(fakeShoppingController.addedItems.length, 1);
    expect(fakeShoppingController.addedItems.first['itemName'], 'Sugar');
    expect(fakeShoppingController.addedItems.first['quantity'], 1.0);
    expect(fakeShoppingController.addedItems.first['unit'], 'pcs');
  });

  test('Homie Voice removes item from shopping list', () async {
    final fakeHome = HomeModel(
      id: 'home-123',
      name: 'My Sweet Home',
      inviteCode: 'ABCDEF',
      currentUserRole: 'OWNER',
      memberCount: 1,
    );

    fakeShoppingController.state = ShoppingState(
      list: ShoppingListModel(
        id: 'list-123',
        homeId: 'home-123',
        name: 'Main List',
        isDefault: true,
        pendingCount: 1,
        completedCount: 0,
        items: [
          ShoppingItemModel(
            id: 'item-oil-1',
            shoppingListId: 'list-123',
            itemName: 'Oil',
            quantity: 1.0,
            unit: 'L',
            categoryIcon: 'oil',
            categoryColor: '#F59E0B',
            isCompleted: false,
            isAutoGenerated: false,
            addedByName: 'Tester',
          ),
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: [
        shoppingControllerProvider.overrideWith((ref) => fakeShoppingController),
        voiceAiServiceProvider.overrideWithValue(
          VoiceAiService(
            voiceRepository: null,
            localExecutor: null,
            isOnline: true,
          ),
        ),
        homeControllerProvider.overrideWith(
          (ref) => FakeHomeController(
            HomeState(activeHome: fakeHome, homes: [fakeHome]),
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    final voiceController = container.read(voiceAiControllerProvider.notifier);

    final commandResult = const VoiceCommandResult(
      transcript: 'shopping list la irukura oil remove pannu',
      intent: VoiceIntentType.removeShoppingItem,
      confidence: 0.95,
      intentConfidence: 0.95,
      productMatchConfidence: 0.95,
      message: 'Removed Oil from shopping list',
      entities: VoiceEntities(
        itemName: 'Oil',
      ),
      detectedLanguage: 'TANGLISH',
    );

    voiceController.state = voiceController.state.copyWith(
      status: VoiceAiStatus.confirming,
      commandResult: commandResult,
    );

    await voiceController.executeCommand();

    final state = container.read(voiceAiControllerProvider);
    expect(state.status, VoiceAiStatus.success);
    expect(state.executionResponse?.success, true);
    expect(state.executionResponse?.message, contains('Removed Oil from shopping list'));
    expect(fakeShoppingController.deletedItemIds, contains('item-oil-1'));
  });

  test('Homie Voice clears completed items from shopping list', () async {
    final fakeHome = HomeModel(
      id: 'home-123',
      name: 'My Sweet Home',
      inviteCode: 'ABCDEF',
      currentUserRole: 'OWNER',
      memberCount: 1,
    );

    final container = ProviderContainer(
      overrides: [
        shoppingControllerProvider.overrideWith((ref) => fakeShoppingController),
        voiceAiServiceProvider.overrideWithValue(
          VoiceAiService(
            voiceRepository: null,
            localExecutor: null,
            isOnline: true,
          ),
        ),
        homeControllerProvider.overrideWith(
          (ref) => FakeHomeController(
            HomeState(activeHome: fakeHome, homes: [fakeHome]),
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    final voiceController = container.read(voiceAiControllerProvider.notifier);

    final commandResult = const VoiceCommandResult(
      transcript: 'clear shopping list',
      intent: VoiceIntentType.clearShoppingList,
      confidence: 0.95,
      intentConfidence: 0.95,
      productMatchConfidence: 0.95,
      message: 'Cleared completed items',
      detectedLanguage: 'EN',
    );

    voiceController.state = voiceController.state.copyWith(
      status: VoiceAiStatus.confirming,
      commandResult: commandResult,
    );

    await voiceController.executeCommand();

    final state = container.read(voiceAiControllerProvider);
    expect(state.status, VoiceAiStatus.success);
    expect(state.executionResponse?.success, true);
    expect(fakeShoppingController.clearedCompletedCalled, isTrue);
  });
}
