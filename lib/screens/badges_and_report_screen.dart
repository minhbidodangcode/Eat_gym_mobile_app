import 'package:flutter/material.dart';
import '../models/badges_and_report_model.dart';
import '../widgets/badge_collection_card.dart';
import '../widgets/badges_header.dart';
import '../widgets/level_progress_card.dart';
import '../widgets/pdf_export_card.dart';

class BadgesAndReportScreen extends StatefulWidget {
  const BadgesAndReportScreen({super.key});

  @override
  State<BadgesAndReportScreen> createState() => _BadgesAndReportScreenState();
}

class _BadgesAndReportScreenState extends State<BadgesAndReportScreen> {
  late final BadgesAndReportModel _model;
  @override
  void initState() {
    super.initState();
    _model = BadgesAndReportModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
          animation: _model,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar & Main Titles
                  BadgesHeader(
                    onAvatarTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mở hồ sơ cá nhân vận động viên'),
                          duration: Duration(milliseconds: 900),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Monolith 1: Overall Level & Progress
                  LevelProgressCard(model: _model),

                  const SizedBox(height: 20),

                  // Monolith 2: Gymer Chef Badge Collection Grid
                  BadgeCollectionCard(model: _model),

                  const SizedBox(height: 20),

                  // Monolith 3: PDF Medical & Clinical Nutrition Export Engine
                  PdfExportCard(model: _model),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
    );
  }
}
