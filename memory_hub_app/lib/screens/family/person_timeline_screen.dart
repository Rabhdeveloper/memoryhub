import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/enhanced_empty_state.dart';
import 'package:intl/intl.dart';

class PersonTimelineScreen extends StatefulWidget {
  final String personId;
  final String personName;
  final String? photoUrl;

  const PersonTimelineScreen({
    Key? key,
    required this.personId,
    required this.personName,
    this.photoUrl,
  }) : super(key: key);

  @override
  State<PersonTimelineScreen> createState() => _PersonTimelineScreenState();
}

class _PersonTimelineScreenState extends State<PersonTimelineScreen> {
  final FamilyService _familyService = FamilyService();
  List<Map<String, dynamic>> _memories = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final memories = await _familyService.getPersonTimeline(widget.personId);
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.personName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                      ),
                    ),
                  ),
                  if (widget.photoUrl != null)
                    Opacity(
                      opacity: 0.3,
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFF4F46E5),
                            backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
                            child: widget.photoUrl == null
                                ? const Icon(Icons.person, color: Colors.white, size: 32)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.history, size: 16, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_memories.length} ${_memories.length == 1 ? 'Memory' : 'Memories'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildShimmerCard(),
                childCount: 3,
              ),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: EnhancedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Timeline',
                  message: 'Failed to load memories. Pull to retry.',
                  actionLabel: 'Retry',
                  onAction: _loadTimeline,
                ),
              ),
            )
          else if (_memories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: EnhancedEmptyState(
                  icon: Icons.timeline,
                  title: 'No Memories Yet',
                  message: 'Tag ${widget.personName} in your memories to see them appear here on their personal timeline.',
                  actionLabel: 'Go to Memories',
                  onAction: () => Navigator.pop(context),
                  gradientColors: const [Color(0xFF4F46E5), Color(0xFF818CF8)],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTimelineItem(_memories[index], index),
                  childCount: _memories.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> memory, int index) {
    final title = memory['title'] ?? 'Untitled Memory';
    final description = memory['description'] ?? '';
    final date = memory['date'] ?? memory['created_at'];
    final mediaUrls = (memory['media_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final tags = (memory['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final location = memory['location'];

    final hasMedia = mediaUrls.isNotEmpty;
    final firstMediaUrl = hasMedia ? mediaUrls.first : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              if (index < _memories.length - 1)
                Container(
                  width: 2,
                  height: 80,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF4F46E5).withOpacity(0.5),
                        const Color(0xFF4F46E5).withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasMedia)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        firstMediaUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDate(date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            if (location != null && location['name'] != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location['name'],
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                            )).toList(),
                          ),
                        ],
                        if (mediaUrls.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.photo_library, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                '+${mediaUrls.length - 1} more ${mediaUrls.length - 1 == 1 ? 'photo' : 'photos'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 40, height: 40, borderRadius: BorderRadius.circular(20)),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.circular(6)),
                    const SizedBox(height: 12),
                    ShimmerBox(width: double.infinity, height: 16, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 200, height: 12, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM d, yyyy').format(parsedDate);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }
}
