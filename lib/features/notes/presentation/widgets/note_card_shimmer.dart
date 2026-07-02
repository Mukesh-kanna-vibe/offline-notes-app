import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_theme.dart';

class NoteCardShimmer extends StatelessWidget {
  const NoteCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 1300),
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.shimmerBlock,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.shimmerBlock,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.shimmerBlock,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const Spacer(),
            Container(
              height: 1,
              color: AppTheme.shimmerBase,
            ),
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.shimmerBlock,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesShimmerList extends StatelessWidget {
  const NotesShimmerList({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 108),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => const NoteCardShimmer(),
    );
  }
}
