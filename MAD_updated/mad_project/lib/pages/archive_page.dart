import 'package:flutter/material.dart';

import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import 'request_details_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key, this.archiveRequests});
  final Future<void> Function(Set<String>)? archiveRequests;
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final selected = <String>{};
  bool saving = false;
  Future<void> archive(Set<String> eligible) async {
    final ids = selected.intersection(eligible);
    if (saving || ids.isEmpty) return;
    setState(() => saving = true);
    try {
      await (widget.archiveRequests ?? RequestService().archiveRequests)(ids);
      if (!mounted) return;
      setState(selected.clear);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Requests archived.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to archive requests. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final returned = requests.where((r) => r.status == 'Returned').toList();
      final eligible = returned
          .where((r) => !r.archived)
          .map((r) => r.id)
          .toSet();
      return TransactionLayout(
        title: 'Archive',
        subtitle: 'Select returned transactions to archive',
        action: IconButton(
          tooltip: saving ? 'Archiving...' : 'Archive selected',
          onPressed: !saving && selected.intersection(eligible).isNotEmpty
              ? () => archive(eligible)
              : null,
          icon: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.archive_outlined),
        ),
        children: [
          if (selected.intersection(eligible).isNotEmpty)
            Text('${selected.intersection(eligible).length} selected'),
          if (returned.isEmpty) const Text('No returned transactions.'),
          for (final request in returned)
            Row(
              children: [
                Checkbox(
                  activeColor: const Color(0xFF00B84A),
                  value: selected.contains(request.id),
                  onChanged: saving || request.archived
                      ? null
                      : (value) => setState(() {
                          if (value == true) {
                            selected.add(request.id);
                          } else {
                            selected.remove(request.id);
                          }
                        }),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (request.archived) const Text('Archived'),
                      TransactionCard(
                        request: request,
                        selected: selected.contains(request.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RequestDetailsPage(requestId: request.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      );
    },
  );
}
