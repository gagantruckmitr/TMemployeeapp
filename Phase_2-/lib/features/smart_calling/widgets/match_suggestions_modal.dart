import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/dummy_data.dart';

class MatchSuggestionsModal extends StatelessWidget {
  const MatchSuggestionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.softGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Top Match Suggestions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppColors.darkGray),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: DummyData.matchSuggestions.length,
              itemBuilder: (context, index) {
                final match = DummyData.matchSuggestions[index];
                return _buildMatchCard(context, match);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match) {
    final matchScore = match['matchScore'] as int;
    final scoreColor = matchScore >= 90
        ? AppColors.success
        : matchScore >= 80
            ? AppColors.slateBlue
            : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softGray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scoreColor.withOpacity(0.1),
                child: Text(
                  match['driverName'].toString().substring(0, 1),
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          match['driverName'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        if (match['verified'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 16, color: AppColors.success),
                        ],
                      ],
                    ),
                    Text(
                      match['tmid'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.softGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$matchScore%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Score Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: matchScore / 100,
              backgroundColor: AppColors.softGray.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 6,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Match Details
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMatchChip('Location', '${match['locationMatch']}%'),
              _buildMatchChip('Truck Type', '${match['truckTypeMatch']}%'),
              _buildMatchChip('Status', match['availability']),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Match proposed to ${match['driverName']}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.handshake, size: 18),
              label: const Text('Propose Match'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.softGray,
        ),
      ),
    );
  }
}
