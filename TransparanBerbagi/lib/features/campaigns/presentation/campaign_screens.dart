import 'package:decentradonate/features/campaigns/data/campaign_repository.dart';
import 'package:decentradonate/features/campaigns/domain/campaign.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

final _list = FutureProvider.autoDispose(
  (ref) async => ref.watch(campaignRepositoryProvider)!.list(),
);
final _detail = FutureProvider.autoDispose.family<Campaign?, String>(
  (ref, id) => ref.watch(campaignRepositoryProvider)!.detail(id),
);
final _allocations = FutureProvider.autoDispose
    .family<List<PublishedAllocation>, String>(
      (ref, id) => ref.watch(campaignRepositoryProvider)!.allocations(id),
    );

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);
final _date = DateFormat('dd/MM/yyyy');

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});

  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Kampanye'),
      leading: BackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    ),
    body: ref.watch(campaignRepositoryProvider) == null
        ? const Center(child: Text('Hubungkan aplikasi ke Supabase.'))
        : ref
              .watch(_list)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _Retry(onPressed: () => ref.invalidate(_list)),
                data: (campaigns) {
                  final results = campaigns.where(
                    (item) => item.matches(_query),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          TextField(
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: const InputDecoration(
                              labelText: 'Cari kampanye',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (results.isEmpty)
                            Text(
                              campaigns.isEmpty
                                  ? 'Belum ada kampanye publik.'
                                  : 'Kampanye tidak ditemukan.',
                            ),
                          for (final campaign in results)
                            Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(campaign.title),
                                subtitle: Text(
                                  '${campaign.category} · ${_idr.format(campaign.raised)} terkumpul',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    context.push('/kampanye/${campaign.id}'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
  );
}

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Detail kampanye')),
    body: ref.watch(campaignRepositoryProvider) == null
        ? const Center(child: Text('Hubungkan aplikasi ke Supabase.'))
        : ref
              .watch(_detail(id))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    _Retry(onPressed: () => ref.invalidate(_detail(id))),
                data: (campaign) {
                  if (campaign == null) {
                    return const Center(
                      child: Text('Kampanye tidak tersedia.'),
                    );
                  }
                  final theme = Theme.of(context);
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            campaign.category,
                            style: theme.textTheme.labelLarge,
                          ),
                          Text(
                            campaign.title,
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(campaign.organizer),
                          const SizedBox(height: 16),
                          Text(
                            '${_idr.format(campaign.raised)} dari ${_idr.format(campaign.target)}',
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: campaign.progress,
                            semanticsLabel: 'Progres penggalangan dana',
                          ),
                          const SizedBox(height: 8),
                          Text('${campaign.donors} donatur'),
                          const SizedBox(height: 20),
                          Text(campaign.story),
                          const SizedBox(height: 24),
                          Text(
                            'Transparansi Dana',
                            style: theme.textTheme.titleLarge,
                          ),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  title: const Text('Terkumpul'),
                                  trailing: Text(_idr.format(campaign.raised)),
                                ),
                                ListTile(
                                  title: const Text('Teralokasi'),
                                  trailing: Text(
                                    _idr.format(campaign.allocated),
                                  ),
                                ),
                                ListTile(
                                  title: const Text('Sisa dana'),
                                  trailing: Text(_idr.format(campaign.balance)),
                                ),
                              ],
                            ),
                          ),
                          ref
                              .watch(_allocations(id))
                              .when(
                                loading: () => const LinearProgressIndicator(),
                                error: (_, _) => _Retry(
                                  onPressed: () =>
                                      ref.invalidate(_allocations(id)),
                                ),
                                data: (items) => items.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Belum ada alokasi yang dipublikasikan.',
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          for (final item in items)
                                            ListTile(
                                              title: Text(item.description),
                                              subtitle: Text(
                                                '${item.category} · ${_date.format(item.publishedAt.toLocal())}',
                                              ),
                                              trailing: Text(
                                                _idr.format(item.amount),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Data belum dapat dimuat.'),
          TextButton(onPressed: onPressed, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}
