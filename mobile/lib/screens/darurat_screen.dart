import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/api_service.dart';
import '../models/emergency_contact_model.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';
import 'edukasi_screen.dart';

class DaruratScreen extends StatefulWidget {
  const DaruratScreen({super.key});

  @override
  State<DaruratScreen> createState() => _DaruratScreenState();
}

class _DaruratScreenState extends State<DaruratScreen> {
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    final contacts = await ApiService().fetchEmergencyContacts();

    // If every item is a fallback item, mark as offline for UI hint
    final isFallback = contacts.every(
      (c) => c.id.startsWith('fallback-'),
    );

    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
        _isOffline = isFallback;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EWSAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              if (_isOffline)
                _buildOfflineBanner(),
              if (_isLoading)
                _buildLoadingShimmer()
              else
                _buildContactList(context),
              _buildBeforeCallingInfo(),
              _buildQuickFlow(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Offline Banner ────────────────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.statusWaspada.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.statusWaspada.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: AppTheme.statusWaspada),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t('offlineFallbackMessage'),
              style: TextStyle(
                color: AppTheme.statusWaspada,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading Shimmer ───────────────────────────────────────────────────────
  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 18,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          ...List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dynamic contact list ──────────────────────────────────────────────────
  Widget _buildContactList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('priorityEmergencyServices'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('emergencyActionSubtitle'),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ..._contacts.map((c) => _ContactCard(contact: c)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('emergencyContactsTitle'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('emergencyContactsSubtitle'),
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.statusBahaya.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.statusBahaya.withAlpha(60),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      context.t('dangerPriorityTag'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.statusBahaya,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t('safetyFirst'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.statusBahaya,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _NavPill(
                label: context.t('openDashboard'),
                onTap: () => navIndexNotifier.value = 1,
              ),
              _NavPill(
                label: context.t('viewSensorMap'),
                onTap: () => navIndexNotifier.value = 2,
              ),
              _NavPill(
                label: context.t('mitigationGuide'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EdukasiScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Before Calling Tips ───────────────────────────────────────────────────
  Widget _buildBeforeCallingInfo() {
    final tips = [
      context.t('beforeCallingTip1'),
      context.t('beforeCallingTip2'),
      context.t('beforeCallingTip3'),
      context.t('beforeCallingTip4'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('callPreparationTitle'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.statusSiaga,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('callPreparationSubtitle'),
            style: TextStyle(color: AppTheme.statusSiaga, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 13, height: 1.4),
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

  // ── Quick Flow ────────────────────────────────────────────────────────────
  Widget _buildQuickFlow() {
    final steps = [
      context.t('quickActionStep1'),
      context.t('quickActionStep2'),
      context.t('quickActionStep3'),
    ];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('quickActionFlowTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(fontSize: 13, height: 1.4),
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
}

// ── Contact Card Widget ───────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  const _ContactCard({required this.contact});

  Color get _cardColor {
    switch (contact.category) {
      case 'BPBD':
        return AppTheme.accentBlue;
      case 'SAR':
        return AppTheme.statusSiaga;
      case 'AMBULANCE':
        return AppTheme.statusBahaya;
      case 'POLICE':
        return const Color(0xFF7C3AED);
      case 'HOSPITAL':
        return const Color(0xFF0D9488);
      default:
        return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _cardColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                contact.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(
                  contact.categoryLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.t('emergencyNumberLabel'),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
          ),
          Text(
            contact.phone,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('serviceFocusLabel'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      Text(
                        contact.focusLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('responseEstimateLabel'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      Text(
                        contact.responseTimeLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text(context.t('callContactTitle', replacements: {'name': contact.name})),
                  content: Text(
                    context.t('callContactPrompt', replacements: {'phone': contact.phone}),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(context.t('cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        final uri = Uri(scheme: 'tel', path: contact.phone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.t('callContactButton', replacements: {'phone': contact.phone})),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.phone, size: 16),
              label: Text(context.t('callContactButton', replacements: {'phone': contact.phone})),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Pill Helper ───────────────────────────────────────────────────────────
class _NavPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF8FAFC),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
