import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quest_template_provider.dart';
import '../../data/models/quest_template.dart';
import '../../app/theme.dart';
import 'create_template_screen.dart';

/// Screen for managing quest templates
class ManageTemplatesScreen extends ConsumerWidget {
  const ManageTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(questTemplateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quest Templates')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.event_repeat,
                      size: 64,
                      color: Colors.white38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No templates yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first recurring quest template',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(context, ref, template);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Template'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    QuestTemplate template,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: template.isActive
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: template.isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (template.isHabit == true)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: template.statType.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.statType.icon,
                      color: template.statType.color,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (template.isHabit == true) ...[
                            const Icon(Icons.local_fire_department,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Streak: ${template.habitStreak}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${template.timeMinutes} min',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: template.isActive,
                  onChanged: (value) => _toggleTemplate(ref, template, value),
                ),
              ],
            ),
            if (template.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  template.difficulty.displayName,
                  template.difficulty.color,
                ),
                _buildChip(
                  template.recurrenceType.displayName,
                  Colors.blue,
                ),
                _buildChip(
                  template.statType.displayName,
                  template.statType.color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editTemplate(context, template),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteTemplate(context, ref, template),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _toggleTemplate(WidgetRef ref, QuestTemplate template, bool value) async {
    try {
      await ref
          .read(questTemplateProvider.notifier)
          .toggleActive(template.id!, value);
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  void _editTemplate(BuildContext context, QuestTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTemplateScreen(template: template),
      ),
    );
  }

  void _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    QuestTemplate template,
  ) {
    _showDeleteDialog(context, ref, template);
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    QuestTemplate template,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete "${template.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(questTemplateProvider.notifier)
                  .deleteTemplate(template.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
