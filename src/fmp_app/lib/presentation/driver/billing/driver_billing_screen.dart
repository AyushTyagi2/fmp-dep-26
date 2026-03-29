import 'package:flutter/material.dart';

class BillingPage extends StatefulWidget {
    const BillingPage({Key? key}) : super(key: key);

    @override
    State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage>
        with SingleTickerProviderStateMixin {
    late TabController _tabController;
    final List<String> tabs = ['Active', 'Completed', 'Pending Payment'];

    @override
    void initState() {
        super.initState();
        _tabController = TabController(length: tabs.length, vsync: this);
    }

    @override
    void dispose() {
        _tabController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Billing'),
                elevation: 0,
                bottom: TabBar(
                    controller: _tabController,
                    tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                ),
            ),
            body: TabBarView(
                controller: _tabController,
                children: [
                    _buildBillingList('Active'),
                    _buildBillingList('Completed'),
                    _buildBillingList('Pending Payment'),
                ],
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _showUploadDialog,
                child: const Icon(Icons.add),
            ),
        );
    }

    Widget _buildBillingList(String status) {
        return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
                return _buildBillingCard(index, status);
            },
        );
    }

    Widget _buildBillingCard(int index, String status) {
        return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
                leading: const Icon(Icons.receipt, color: Colors.blue),
                title: Text('Bill #${1001 + index}'),
                subtitle: Text('Amount: \$${(index + 1) * 50}'),
                trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                        const PopupMenuItem(child: Text('View')),
                        const PopupMenuItem(child: Text('Download')),
                        const PopupMenuItem(child: Text('Share')),
                    ],
                ),
                onTap: () => _showBillDetails(index, status),
            ),
        );
    }

    void _showBillDetails(int index, String status) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text('Bill #${1001 + index}'),
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text('Status: $status'),
                        const SizedBox(height: 8),
                        Text('Amount: \$${(index + 1) * 50}'),
                        const SizedBox(height: 8),
                        Text('Date: ${DateTime.now()}'),
                    ],
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ],
            ),
        );
    }

    void _showUploadDialog() {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Upload Bill'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Choose File'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            decoration: InputDecoration(
                                hintText: 'Bill Description',
                                border: OutlineInputBorder(),
                            ),
                        ),
                    ],
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Upload')),
                ],
            ),
        );
    }
}