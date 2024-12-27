import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart';

class AudioQualitySettingsPage extends StatelessWidget {
  const AudioQualitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '音质设置'),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('自动调整音质'),
                subtitle: const Text('根据网络状况自动调整音质'),
                value: settings.autoQuality,
                onChanged: (value) => settings.setAutoQuality(value),
              ),
              const Divider(),
              if (!settings.autoQuality) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '音质选择',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...SettingsProvider.bitRateOptions.map((bitRate) {
                        return RadioListTile<int>(
                          title: Text(SettingsProvider.getBitRateDescription(bitRate)),
                          subtitle: bitRate == 0
                              ? const Text('使用原始音质，可能会消耗更多流量')
                              : Text('建议网络环境：${_getNetworkSuggestion(bitRate)}'),
                          value: bitRate,
                          groupValue: settings.maxBitRate,
                          onChanged: (value) {
                            if (value != null) {
                              settings.setMaxBitRate(value);
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '说明：\n'
                  '1. 更高的音质需要更好的网络环境\n'
                  '2. 更高的音质会消耗更多的流量和电量\n'
                  '3. 建议在 WiFi 环境下使用高音质\n'
                  '4. 自动调整会根据网络状况选择合适的音质',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getNetworkSuggestion(int bitRate) {
    switch (bitRate) {
      case 96:
        return '2G/3G';
      case 128:
        return '3G/4G';
      case 192:
        return '4G/WiFi';
      case 320:
        return 'WiFi';
      default:
        return '任意';
    }
  }
} 