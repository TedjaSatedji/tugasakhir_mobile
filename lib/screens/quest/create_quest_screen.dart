import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/quest_model.dart';
import '../../providers/quest_provider.dart';

class CreateQuestScreen extends StatefulWidget {
  const CreateQuestScreen({super.key});

  @override
  State<CreateQuestScreen> createState() => _CreateQuestScreenState();
}

class _CreateQuestScreenState extends State<CreateQuestScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _xpRewardController;
  late TextEditingController _moneyRewardController;

  QuestCategory _selectedCategory = QuestCategory.health;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _xpRewardController = TextEditingController(text: '100');
    _moneyRewardController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _xpRewardController.dispose();
    _moneyRewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createQuest),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              AppStrings.questName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama quest',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              AppStrings.questDescription,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Masukkan deskripsi quest',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // XP Reward
            const Text(
              'XP Reward',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _xpRewardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Money Reward
            const Text(
              'Uang Reward (Rp)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _moneyRewardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            const Text(
              AppStrings.questCategory,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<QuestCategory>(
              value: _selectedCategory,
              isExpanded: true,
              items: QuestCategory.values
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.name.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Deadline
            const Text(
              AppStrings.questDeadline,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDeadline = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryNeon),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDeadline.toString().split(' ')[0],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryNeon,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul quest harus diisi')),
                    );
                    return;
                  }

                  context.read<QuestProvider>().createQuest(
                    _titleController.text,
                    _descriptionController.text,
                    int.tryParse(_xpRewardController.text) ?? 100,
                    double.tryParse(_moneyRewardController.text) ?? 0,
                    _selectedCategory,
                    _selectedDeadline,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.successCreateQuestMessage),
                    ),
                  );
                },
                child: const Text(
                  AppStrings.createQuest,
                  style: TextStyle(
                    color: AppColors.darkBg,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}