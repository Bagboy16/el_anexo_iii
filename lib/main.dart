import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = 'https://hhiseroubcpqxqvajlyy.supabase.co';
  await Supabase.initialize(
      url: supabaseUrl,
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoaXNlcm91YmNwcXhxdmFqbHl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzQyNzYyMTIsImV4cCI6MTk4OTg1MjIxMn0.c5EE4Y6cjdcWl8-ZPtp3_5clxWF42yzaV3xOPnvFd14');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Anexo III: Más anexado que nunca',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'El Anexo III: Más anexado que nunca'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _stream = Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id']).limit(40);

  final _controller = TextEditingController();

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    Supabase.instance.client
        .channel('messages')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              debugPrint('');
             
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });  
            })
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  debugPrint('Cambios recibidos por stream ${snapshot.data}');
                  final data = snapshot.data as List;
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final message = data[index];
                      return MessageCard(message: message['content']);
                    },
                  );
                },
              ),
            ),
            Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje',
                        ),
                        controller: _controller,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        //submit text
                        final content = _controller.text;
                        await Supabase.instance.client.from('messages').upsert([
                          {'content': content}
                        ]);
                        _controller.clear();
                      },
                    )
                  ],
                ))
          ],
        ));
  }

  Widget MessageCard({required String message}) {
    return Card(
      child: ListTile(
        title: Text(message),
      ),
    );
  }
}
