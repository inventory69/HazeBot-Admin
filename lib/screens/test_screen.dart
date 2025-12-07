import 'package:flutter/material.dart';
import '../services/error_reporter.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _errorReporter = ErrorReporter();
  bool _isProcessing = false;

  Future<void> _triggerTestError() async {
    setState(() => _isProcessing = true);
    
    try {
      // Log some actions (buffered locally, NOT sent automatically)
      _errorReporter.info('Test button clicked', context: {
        'screen': 'TestScreen',
        'action': 'trigger_error',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _errorReporter.debug('Preparing to throw test exception', context: {
        'will_catch': true,
        'error_type': 'intentional',
      });
      
      _errorReporter.info('Throwing exception in 1 second...');
      
      await Future.delayed(const Duration(seconds: 1));
      
      _errorReporter.warning('About to throw exception NOW');
      
      // Intentionally throw an error
      throw Exception('This is a test error for remote logging! 🐛');
      
    } catch (e, stackTrace) {
      _errorReporter.error('Test exception caught', context: {
        'error': e.toString(),
        'expected': true,
      });
      
      // Show error dialog with consent option
      if (mounted) {
        await _errorReporter.reportError(
          context,
          e,
          stackTrace: stackTrace,
          additionalContext: {
            'screen': 'TestScreen',
            'action': 'trigger_test_error',
            'user_triggered': true,
            'test_scenario': 'intentional_error',
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Features',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    'Development testing area',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Error Reporting Test Card
          Card(
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Theme.of(context).colorScheme.error,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Remote Error Reporting Test',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This button will intentionally throw an error to test the remote error reporting system.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What happens:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildTestStep(context, '1', 'Logs actions locally (not sent)'),
                  _buildTestStep(context, '2', 'Throws a test exception'),
                  _buildTestStep(context, '3', 'Shows consent dialog'),
                  _buildTestStep(context, '4', 'If you click "Send Report": Sends to backend'),
                  _buildTestStep(context, '5', 'Backend logs appear in HazeBot.log'),
                  const SizedBox(height: 20),
                  
                  // Test Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _triggerTestError,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.bug_report),
                      label: Text(_isProcessing
                          ? 'Triggering Error...'
                          : 'Trigger Test Error'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(all: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                      )),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expected Backend Log:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '[FLUTTER ERROR REPORT] Exception: This is a test error for remote logging! 🐛',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'About Remote Error Reporting',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    context,
                    Icons.privacy_tip,
                    'Privacy First',
                    'No logs are sent automatically. User consent required.',
                  ),
                  _buildInfoItem(
                    context,
                    Icons.memory,
                    'Local Buffering',
                    'Logs stored locally during operations, discarded on success.',
                  ),
                  _buildInfoItem(
                    context,
                    Icons.send,
                    'Error-Triggered',
                    'Only sends logs when error occurs AND user consents.',
                  ),
                  _buildInfoItem(
                    context,
                    Icons.code,
                    'Context-Aware',
                    'Includes stack trace, device info, and action history.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
