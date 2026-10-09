import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/campaign_list_provider.dart';
import '../widgets/campaign_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignListProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.ripple,
          onRefresh: () async => ref.invalidate(campaignListProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamat datang',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.fraunces(
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                          children: const [
                            TextSpan(text: 'Receh kecil,\n'),
                            TextSpan(
                              text: 'riak besar.',
                              style: TextStyle(color: AppColors.ripple),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _HeroBanner(),
                      const SizedBox(height: 12),
                      const SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _Chip(label: 'Semua', active: true),
                            _Chip(label: 'Air'),
                            _Chip(label: 'Pendidikan'),
                            _Chip(label: 'Pangan'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              campaigns.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingWidget(),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateWidget(
                    title: 'Gagal memuat kampanye',
                    subtitle: error.toString().replaceFirst('Exception: ', ''),
                    onRetry: () =>
                        ref.read(campaignListProvider.notifier).retry(),
                  ),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        title: 'Belum ada kampanye',
                        subtitle:
                            'Kampanye yang tersinkron dari blockchain akan muncul di sini.',
                        icon: Icons.volunteer_activism_outlined,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final campaign = data[i];
                        return CampaignCard(
                          campaign: campaign,
                          onTap: () => context.push(
                            '/campaign/${campaign.id}',
                            extra: campaign,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: _RippleArt(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('● DAMPAK TERBUKTI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.verified,
                  )),
              const SizedBox(height: 6),
              Text('Mulai dari 0,01 MATIC',
                  style: GoogleFonts.fraunces(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paper,
                  )),
              const SizedBox(height: 4),
              const SizedBox(
                width: 190,
                child: Text(
                  'Setiap donasi tercatat di blockchain dan dibuktikan lewat foto serta lokasi.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB9C7BE)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RippleArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: CustomPaint(painter: _RippleArtPainter()),
    );
  }
}

class _RippleArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.verified;
    for (final r in [16.0, 34.0, 54.0, 74.0]) {
      paint.color = AppColors.verified.withValues(alpha: 1 - (r / 90));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;

  const _Chip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: active ? AppColors.paper : AppColors.ink,
        ),
      ),
    );
  }
}
