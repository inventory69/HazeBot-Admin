import 'package:flutter/material.dart';
import '../models/cog.dart';

class CogCard extends StatefulWidget {
  final Cog cog;
  final VoidCallback? onLoad;
  final VoidCallback? onUnload;
  final VoidCallback? onReload;
  final VoidCallback? onShowLogs;
  final bool isMobile;

  const CogCard({
    super.key,
    required this.cog,
    this.onLoad,
    this.onUnload,
    this.onReload,
    this.onShowLogs,
    this.isMobile = false,
  });

  @override
  State<CogCard> createState() => _CogCardState();
}

class _CogCardState extends State<CogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = widget.cog.getCategoryColor();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.cog.status == CogStatus.loaded 
              ? categoryColor.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.15),
                  categoryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
            child: Row(
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.cog.materialIcon,
                    color: categoryColor,
                    size: widget.isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(width: widget.isMobile ? 12 : 16),
                
                // Cog name and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cog.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: widget.isMobile ? 18 : 20,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.cog.categoryDisplay,
                              style: TextStyle(
                                color: categoryColor.withOpacity(0.9),
                                fontSize: widget.isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                _buildStatusBadge(context),
              ],
            ),
          ),

          // Description and features
          Padding(
            padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (widget.cog.description != null && widget.cog.description!.isNotEmpty)
                  Text(
                    widget.cog.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: widget.isMobile ? 13 : 14,
                          height: 1.5,
                        ),
                  ),

                // Features (collapsible)
                if (widget.cog.features.isNotEmpty) ...[
                  SizedBox(height: widget.isMobile ? 12 : 16),
                  
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.cog.features.length} Features',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: widget.isMobile ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.cog.features.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: categoryColor.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                feature,
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 11 : 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],

                SizedBox(height: widget.isMobile ? 16 : 20),

                // Action buttons
                Wrap(
                  spacing: widget.isMobile ? 6 : 8,
                  runSpacing: widget.isMobile ? 6 : 8,
                  children: [
                    if (widget.cog.canLoad && widget.onLoad != null)
                      _buildActionButton(
                        context,
                        icon: Icons.play_arrow,
                        label: 'Load',
                        color: Colors.green,
                        onPressed: widget.onLoad!,
                      ),
                    if (widget.cog.canUnload && widget.onUnload != null)
                      _buildActionButton(
                        context,
                        icon: Icons.stop,
                        label: 'Unload',
                        color: Colors.orange,
                        onPressed: widget.onUnload!,
                      ),
                    if (widget.cog.canReload && widget.onReload != null)
                      _buildActionButton(
                        context,
                        icon: Icons.refresh,
                        label: 'Reload',
                        color: Colors.blue,
                        onPressed: widget.onReload!,
                      ),
                    if (widget.onShowLogs != null)
                      _buildActionButton(
                        context,
                        icon: Icons.description,
                        label: 'Logs',
                        color: Colors.grey,
                        onPressed: widget.onShowLogs!,
                        outlined: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (widget.cog.status) {
      case CogStatus.loaded:
        backgroundColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        statusText = 'Loaded';
        break;
      case CogStatus.unloaded:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey[700]!;
        icon = Icons.radio_button_unchecked;
        statusText = 'Unloaded';
        break;
      case CogStatus.disabled:
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        statusText = 'Disabled';
        break;
      case CogStatus.error:
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red[700]!;
        icon = Icons.error;
        statusText = 'Error';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 10 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: widget.isMobile ? 14 : 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: widget.isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: widget.isMobile ? 16 : 18),
            label: Text(label, style: TextStyle(fontSize: widget.isMobile ? 13 : 14)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 16,
                vertical: widget.isMobile ? 8 : 12,
              ),
              side: BorderSide(color: color.withOpacity(0.5)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: widget.isMobile ? 16 : 18),
            label: Text(label, style: TextStyle(fontSize: widget.isMobile ? 13 : 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 16,
                vertical: widget.isMobile ? 8 : 12,
              ),
            ),
          );
  }
}