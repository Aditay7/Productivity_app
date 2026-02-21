import re

with open('lib/screens/quests/quests_screen.dart', 'r') as f:
    content = f.read()

start_marker = "// ─────────────────────────────────────────────────────────────────────────────\n// QUEST CARD"
end_marker = "// ─────────────────────────────────────────────────────────────────────────────\n// EMPTY STATE"

if start_marker not in content or end_marker not in content:
    print("Markers not found!")
    exit(1)

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

new_code = """// ─────────────────────────────────────────────────────────────────────────────
// QUEST CARD — Premium RPG Design (Linear / Arc / Superhuman style)
// ─────────────────────────────────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final dynamic quest;
  final bool isActive;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const _QuestCard({
    required this.quest,
    required this.isActive,
    this.isCompleting = false,
    this.onComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return isActive 
        ? _ActiveQuestCard(quest: quest, isCompleting: isCompleting, onComplete: onComplete, onTap: onTap)
        : _DoneQuestCard(quest: quest, onTap: onTap);
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────
Difficulty _difficultyFromQuest(dynamic quest) {
  try {
    return Difficulty.values.firstWhere(
      (d) => d.toString().split('.').last == quest.difficulty,
      orElse: () => Difficulty.E,
    );
  } catch (_) {
    return Difficulty.E;
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

// ── Active Card Implementation ──────────────────────────────────────────────
class _ActiveQuestCard extends StatefulWidget {
  final dynamic quest;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const _ActiveQuestCard({
    required this.quest,
    required this.isCompleting,
    this.onComplete,
    this.onTap,
  });

  @override
  State<_ActiveQuestCard> createState() => _ActiveQuestCardState();
}

class _ActiveQuestCardState extends State<_ActiveQuestCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statColor = widget.quest.statType.color as Color;
    final diff = _difficultyFromQuest(widget.quest);
    
    // Add implicit animation for hover lift
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF141A2A), // Card Background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.06), // Soft borders
              width: 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Left-side vertical stat color strip (4px)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: statColor),
                ),
                
                // Subtle radial glow behind the icon
                Positioned(
                  left: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          statColor.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A2135), // Elevated hover color base
                          border: Border.all(color: statColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: statColor.withOpacity(0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.quest.statType.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Content Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quest.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            if (widget.quest.description != null && widget.quest.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.quest.description!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            
                            // Pills Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PremiumPill(label: widget.quest.statType.name.toUpperCase(), color: statColor),
                                _PremiumPill(label: diff.name, color: diff.color),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Text Info Row
                            Text(
                              'XP: +${widget.quest.xpReward} ⚡  •  ${widget.quest.timeEstimatedMinutes}m',
                              style: TextStyle(
                                color: statColor.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            
                            if (widget.quest.timeActualSeconds != null && widget.quest.timeActualSeconds > 0) ...[
                              const SizedBox(height: 12),
                              QuestTimerWidget(quest: widget.quest, onTap: widget.onTap),
                            ]
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Action Button
                      _CircularPulseButton(
                        isCompleting: widget.isCompleting,
                        onTap: widget.onComplete,
                        color: statColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Done Card Implementation ────────────────────────────────────────────────
class _DoneQuestCard extends StatelessWidget {
  final dynamic quest;
  final VoidCallback? onTap;

  const _DoneQuestCard({required this.quest, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statColor = quest.statType.color as Color;
    final diff = _difficultyFromQuest(quest);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141A2A).withOpacity(0.85), // Muted Background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Circle (Muted / Checked)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: Colors.green, size: 22),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          height: 1.2,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white.withOpacity(0.4),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        '+${quest.xpReward} XP Earned ✨',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                       Text(
                        'Completed ${quest.completedAt != null ? _timeAgo(quest.completedAt!) : 'recently'} • Duration ${quest.timeEstimatedMinutes}m',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'Stat: ${quest.statType.name}  •  Difficulty: ${diff.name}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      if (quest.productivityScore != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Focus Score: ${quest.productivityScore!.round()}% 🎯',
                          style: TextStyle(
                            color: Colors.blue.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Premium Widgets ────────────────────────────────────────────────
class _PremiumPill extends StatelessWidget {
  final String label;
  final Color color;
  const _PremiumPill({required this.label, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CircularPulseButton extends StatefulWidget {
  final bool isCompleting;
  final VoidCallback? onTap;
  final Color color;
  
  const _CircularPulseButton({
    required this.isCompleting,
    this.onTap,
    required this.color,
  });

  @override
  State<_CircularPulseButton> createState() => _CircularPulseButtonState();
}

class _CircularPulseButtonState extends State<_CircularPulseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isCompleting ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCompleting || _isHovered 
                ? widget.color.withOpacity(0.15) 
                : Colors.transparent,
            border: Border.all(
              color: widget.isCompleting 
                  ? Colors.transparent 
                  : _isHovered 
                      ? widget.color 
                      : widget.color.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: widget.isCompleting
              ? const Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.check_rounded, 
                    color: _isHovered ? widget.color : Colors.white.withOpacity(0.6), 
                    size: 20
                  ),
                ),
        ),
      ),
    );
  }
}

"""

with open('lib/screens/quests/quests_screen.dart', 'w') as f:
    f.write(content[:start_idx] + new_code + content[end_idx:])

print("Successfully replaced UI components.")
